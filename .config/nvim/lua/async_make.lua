local M = {}

-- Store current job ID to allow cancellation
M.current_job = nil

function M.stop()
    if M.current_job then
        vim.fn.jobstop(M.current_job)
        M.current_job = nil
    end
end

function M.make(arg)
    -- Stop previous job if it's still running
    M.stop()

    local bufnr = vim.api.nvim_get_current_buf()

    -- Get makeprg: buffer-local > global > "make"
    local makeprg = vim.api.nvim_get_option_value("makeprg", { buf = bufnr })
    if makeprg == "" then
        makeprg = vim.api.nvim_get_option_value("makeprg", { scope = "global" })
    end
    if not makeprg or makeprg == "" then makeprg = "make" end

    -- Get errorformat: buffer-local > global
    local efm = vim.api.nvim_get_option_value("errorformat", { buf = bufnr })
    if efm == "" then
        efm = vim.api.nvim_get_option_value("errorformat", { scope = "global" })
    end

    -- Expand the command and append arguments
    -- expandcmd handles things like % (current file)
    local expanded_args = vim.fn.expand(arg)
    local cmd = vim.fn.expandcmd(makeprg)
    if expanded_args ~= "" then
        cmd = cmd .. " " .. expanded_args
    end

    local lines = {}
    local start_time = vim.uv.hrtime()
    vim.g.async_make_status = '[Building...]'

    -- Use QuickFixCmdPre for compatibility with other plugins
    vim.api.nvim_exec_autocmds("QuickFixCmdPre", { pattern = "make" })

    M.current_job = vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then table.insert(lines, line) end
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then table.insert(lines, line) end
                end
            end
        end,
        on_exit = function(_, exit_code)
            M.current_job = nil

            -- Prepare qf options
            local qf_opts = {
                title = cmd,
                lines = lines,
            }

            -- Only pass efm if we actually found a pattern to avoid E378
            if efm and efm ~= "" then
                qf_opts.efm = efm
            end

            -- Populate list
            vim.fn.setqflist({}, " ", qf_opts)

            -- Calculate build duration
            local elapsed_ms = (vim.uv.hrtime() - start_time) / 1e6
            local duration = elapsed_ms > 1000
                and string.format("%.2fs", elapsed_ms / 1000)
                or string.format("%dms", elapsed_ms)

            -- Check for errors that matched the errorformat
            local qflist = vim.fn.getqflist()
            local valid_errors = 0
            for _, item in ipairs(qflist) do
                if item.valid == 1 then valid_errors = valid_errors + 1 end
            end

            if valid_errors > 0 then
                vim.g.async_make_status = string.format('[%d alerts (%s)]', valid_errors, duration)
                vim.cmd("copen")
                -- Jump to first error if the build failed
                if exit_code ~= 0 then
                    pcall(vim.cmd, "cfirst")
                end
            elseif exit_code ~= 0 then
                -- Build failed but no matches found in output
                vim.g.async_make_status = string.format('[Failed (%s)]', duration)
                if M.current_job then
                    vim.cmd("copen")
                else
                    vim.g.async_make_status = '[Build cancelled]'
                end
            else
                -- Successful build
                vim.cmd("cclose")
                vim.g.async_make_status = string.format('[Built in %s]', duration)
            end

            -- Cleanup status line after 15 seconds
            vim.defer_fn(function()
                if not M.current_job then vim.g.async_make_status = "" end
            end, 15000)

            vim.api.nvim_exec_autocmds("QuickFixCmdPost", { pattern = "make" })
        end
    })

    if M.current_job <= 0 then
        vim.notify("AsyncMake: Failed to start", vim.log.levels.ERROR)
        M.current_job = nil
        vim.g.async_make_status = ""
    end
end

return M

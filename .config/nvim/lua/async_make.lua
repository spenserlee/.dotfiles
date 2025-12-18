local M = {}

-- State management
M.current_job = nil
M.ui = {
    timer = nil,
    buf = nil,
    win = nil,
    augroup = nil, -- Added to track the resize handler
    frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    idx = 1
}

local function stop_spinner()
    -- Clean up the resize handler
    if M.ui.augroup then
        vim.api.nvim_del_augroup_by_id(M.ui.augroup)
        M.ui.augroup = nil
    end

    if M.ui.timer then
        M.ui.timer:stop()
        M.ui.timer:close()
        M.ui.timer = nil
    end
    if M.ui.win and vim.api.nvim_win_is_valid(M.ui.win) then
        vim.api.nvim_win_close(M.ui.win, true)
    end
    if M.ui.buf and vim.api.nvim_buf_is_valid(M.ui.buf) then
        vim.api.nvim_buf_delete(M.ui.buf, { force = true })
    end
    M.ui.win = nil
    M.ui.buf = nil
end

-- Helper to calculate position based on current editor size
local function get_spinner_pos()
    -- row: vim.o.lines - 1 (cmdline) - 1 (statusline) - 1 (height of float)
    -- If laststatus=3 (global statusline) or 2, we account for it.
    local row = vim.o.lines - (vim.o.laststatus > 0 and 3 or 2)
    local col = vim.o.columns
    return row, col
end

local function start_spinner()
    stop_spinner()

    M.ui.buf = vim.api.nvim_create_buf(false, true)

    local row, col = get_spinner_pos()

    local opts = {
        relative = "editor",
        width = 12,
        height = 1,
        row = row,
        col = col,
        anchor = "SE",
        style = "minimal",
        focusable = false,
        noautocmd = true,
        border = "none",
    }

    M.ui.win = vim.api.nvim_open_win(M.ui.buf, false, opts)

    -- Set window options
    vim.api.nvim_set_option_value("winblend", 20, { win = M.ui.win })
    vim.api.nvim_set_option_value("winhl", "Normal:MsgArea", { win = M.ui.win })

    -- Add Autocommand to handle Resize events
    M.ui.augroup = vim.api.nvim_create_augroup("AsyncMakeSpinner", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", {
        group = M.ui.augroup,
        callback = function()
            if M.ui.win and vim.api.nvim_win_is_valid(M.ui.win) then
                local new_row, new_col = get_spinner_pos()
                vim.api.nvim_win_set_config(M.ui.win, {
                    relative = "editor",
                    row = new_row,
                    col = new_col,
                })
            end
        end,
    })

    M.ui.timer = vim.uv.new_timer()
    M.ui.timer:start(0, 100, vim.schedule_wrap(function()
        if not M.ui.buf or not vim.api.nvim_buf_is_valid(M.ui.buf) then return end

        local frame = M.ui.frames[M.ui.idx]
        vim.api.nvim_buf_set_lines(M.ui.buf, 0, -1, false, { " Building " .. frame })
        M.ui.idx = (M.ui.idx % #M.ui.frames) + 1
    end))
end

function M.stop()
    stop_spinner()
    if M.current_job then
        vim.fn.jobstop(M.current_job)
        M.current_job = nil
        vim.g.async_make_status = "[Build cancelled]"
        vim.cmd("redrawstatus")
        vim.defer_fn(function()
            if not M.current_job and not M.ui.timer then
                vim.g.async_make_status = ""
                vim.cmd("redrawstatus")
            end
        end, 3000)
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
    local expanded_args = vim.fn.expand(arg)
    local cmd = vim.fn.expandcmd(makeprg)
    if expanded_args ~= "" then
        cmd = cmd .. " " .. expanded_args
    end

    local lines = {}
    local start_time = vim.uv.hrtime()

    start_spinner()
    vim.g.async_make_status = "" -- Clear status line while building

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
            stop_spinner()
            local was_cancelled = (M.current_job == nil)
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

            -- Populate quickfix list
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
                vim.g.async_make_status = was_cancelled and "[Build cancelled]" or string.format('[Failed (%s)]', duration)
                if not was_cancelled then vim.cmd("copen") end
            else
                -- Successful build
                vim.cmd("cclose")
                vim.g.async_make_status = string.format('[Built in %s]', duration)
            end

            -- One redraw to show the final result in the status line
            vim.cmd("redrawstatus")

            -- Cleanup status line after 15 seconds
            vim.defer_fn(function()
                if not M.current_job and not M.ui.timer then
                    vim.g.async_make_status = ""
                    vim.cmd("redrawstatus")
                end
            end, 15000)

            vim.api.nvim_exec_autocmds("QuickFixCmdPost", { pattern = "make" })
        end
    })

    if M.current_job <= 0 then
        stop_spinner()
        vim.notify("AsyncMake: Failed to start", vim.log.levels.ERROR)
        M.current_job = nil
        vim.g.async_make_status = ""
    end
end

return M

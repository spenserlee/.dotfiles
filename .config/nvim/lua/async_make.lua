local M = {}

function M.make(arg)
    local lines = {""}
    local winnr = vim.fn.win_getid()
    local bufnr = vim.api.nvim_win_get_buf(winnr)

    local makeprg = vim.o.makeprg or vim.api.nvim_buf_get_option(bufnr, "makeprg")
    if not makeprg then
        vim.g.async_make_status = '[no makeprg]'
        return
    end

    local args = vim.fn.expand(arg)
    local cmd = vim.fn.expandcmd(makeprg) .. " " .. args

    vim.g.async_make_status = '[Building...]'

    local function on_event(_, data, event)
        if event == "stdout" or event == "stderr" then
            if data then
                vim.list_extend(lines, data)
            end
        end

        if event == "exit" then
            -- Debug the contents of 'lines' before setqflist
            bufnr = vim.api.nvim_win_get_buf(vim.fn.win_getid())
            local efm = vim.o.errorformat or vim.api.nvim_buf_get_option(bufnr, "errorformat")

            local ok, err = pcall(vim.fn.setqflist, {}, " ",
                {
                    title = cmd,
                    lines = lines,
                    efm = efm
                }
            )
            if not ok then
                vim.fn.writefile({"Error in setqflist: " .. err}, "/tmp/async_make_debug.txt", "a")
                vim.g.async_make_status = '[setqflist error]'
            else
                -- If there are any items in the quickfix list, open quickfix window
                local qflist = vim.fn.getqflist()
                if #qflist > 0 then
                    vim.api.nvim_command("copen")
                end
            end
            vim.g.async_make_status = ''
            vim.api.nvim_command("doautocmd QuickFixCmdPost")
        end
    end

    local job_id = vim.fn.jobstart(
        cmd,
        {
            on_stderr = on_event,
            on_stdout = on_event,
            on_exit = on_event,
            stdout_buffered = true,
            stderr_buffered = true
        }
    )
    if job_id == 0 then
        vim.notify("Failed to start job")
    elseif job_id == -1 then
        vim.notify("Invalid command or executable not found")
    end
end

return M

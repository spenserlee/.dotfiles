local M = {}

-- State management
M.current_job = nil
M.generation = 0
M.ui = {
    timer = nil,
    watch_timer = nil,
    watch_augroup = nil,
    external_active = false,
    notify_dir = nil,
    notify_prefix = nil,
    buf = nil,
    win = nil,
    augroup = nil, -- Added to track the resize handler
    frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    idx = 1
}

-- Work project is built through its Meson wrapper even from Rust buffers. Cargo
-- sets buffer-local makeprg/errorformat for Rust, so use the global values here.
local function is_work_project()
    local cwd = vim.fn.getcwd()
    return vim.uv.fs_stat(cwd .. "/ipsdev") ~= nil
        and vim.uv.fs_stat(cwd .. "/version.conf") ~= nil
end

local function get_make_context(bufnr)
    if is_work_project() then
        return vim.api.nvim_get_option_value("makeprg", { scope = "global" }),
            vim.api.nvim_get_option_value("errorformat", { scope = "global" }),
            true
    end

    local makeprg = vim.api.nvim_get_option_value("makeprg", { buf = bufnr })
    if makeprg == "" then
        makeprg = vim.api.nvim_get_option_value("makeprg", { scope = "global" })
    end
    if not makeprg or makeprg == "" then makeprg = "make" end

    local efm = vim.api.nvim_get_option_value("errorformat", { buf = bufnr })
    if efm == "" then
        efm = vim.api.nvim_get_option_value("errorformat", { scope = "global" })
    end

    return makeprg, efm, false
end

local function refresh_notify_state()
    local cwd = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
    local workdir_id = vim.fn.sha256(cwd)
    local passwd = vim.uv.os_get_passwd()
    local uid = passwd and passwd.uid or "user"
    local runtime_dir = vim.env.XDG_RUNTIME_DIR or vim.env.TMPDIR or "/tmp"
    runtime_dir = runtime_dir:gsub("/+$", "")
    M.ui.notify_dir = runtime_dir .. "/ips-build-" .. tostring(uid)
    M.ui.notify_prefix = "ips-build-" .. workdir_id .. "."
end

local function marker_process_active(pid, marker_path)
    local ok, result = pcall(vim.uv.kill, pid, 0)
    if not ok or result ~= 0 then
        pcall(vim.uv.fs_unlink, marker_path)
        return false
    end

    -- Avoid stale markers that happen to collide with a reused PID.
    local cmdline_file = io.open("/proc/" .. pid .. "/cmdline", "rb")
    if cmdline_file then
        local cmdline = cmdline_file:read("*a") or ""
        cmdline_file:close()
        if not cmdline:find("ips_build.sh", 1, true) then
            pcall(vim.uv.fs_unlink, marker_path)
            return false
        end
    end

    return true
end

local function external_build_active()
    if not M.ui.notify_dir then
        refresh_notify_state()
    end

    local scan = vim.uv.fs_scandir(M.ui.notify_dir)
    if not scan then return false end

    while true do
        local name = vim.uv.fs_scandir_next(scan)
        if not name then break end

        local prefix = M.ui.notify_prefix
        if name:sub(1, #prefix) == prefix then
            local pid = tonumber(name:sub(#prefix + 1))
            if pid then
                local marker_path = M.ui.notify_dir .. "/" .. name
                if marker_process_active(pid, marker_path) then
                    return true
                end
            end
        end
    end

    return false
end

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

-- Move the float with the active tabpage and keep it anchored on resizes.
local function reposition_spinner()
    if not (M.ui.win and vim.api.nvim_win_is_valid(M.ui.win)) then return end

    local row, col = get_spinner_pos()
    local config = {
        relative = "editor",
        row = row,
        col = col,
    }

    local ok, win = pcall(vim.api.nvim_get_current_win)
    if ok then
        config.win = win
    end
    pcall(vim.api.nvim_win_set_config, M.ui.win, config)
end

local function start_spinner()
    if M.ui.timer
        and M.ui.win and vim.api.nvim_win_is_valid(M.ui.win)
        and M.ui.buf and vim.api.nvim_buf_is_valid(M.ui.buf)
    then
        return
    end

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

    -- Add Autocommand to handle Resize and tabpage changes
    M.ui.augroup = vim.api.nvim_create_augroup("AsyncMakeSpinner", { clear = true })
    vim.api.nvim_create_autocmd({ "VimResized", "TabEnter" }, {
        group = M.ui.augroup,
        callback = reposition_spinner,
    })

    M.ui.timer = vim.uv.new_timer()
    M.ui.timer:start(0, 100, vim.schedule_wrap(function()
        if not M.ui.buf or not vim.api.nvim_buf_is_valid(M.ui.buf) then return end

        local frame = M.ui.frames[M.ui.idx]
        vim.api.nvim_buf_set_lines(M.ui.buf, 0, -1, false, { " Building " .. frame })
        M.ui.idx = (M.ui.idx % #M.ui.frames) + 1
    end))
end

local function update_spinner()
    if M.current_job or M.ui.external_active then
        start_spinner()
    else
        stop_spinner()
    end
end

function M.stop()
    M.generation = M.generation + 1
    if M.current_job then
        local job = M.current_job
        M.current_job = nil
        vim.fn.jobstop(job)
        vim.g.async_make_status = "[Build cancelled]"
        vim.cmd("redrawstatus")
        vim.api.nvim_exec_autocmds("QuickFixCmdPost", { pattern = "make" })
        vim.defer_fn(function()
            if not M.current_job and not M.ui.timer then
                vim.g.async_make_status = ""
                vim.cmd("redrawstatus")
            end
        end, 3000)
    end

    M.ui.external_active = external_build_active()
    update_spinner()
end

function M.make(arg)
    -- Stop previous job if it's still running
    M.stop()
    local generation = M.generation

    local bufnr = vim.api.nvim_get_current_buf()
    local makeprg, efm, source_only = get_make_context(bufnr)

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
            -- Cancelled or superseded jobs must not overwrite newer results.
            if generation ~= M.generation then return end

            M.current_job = nil
            M.ui.external_active = external_build_active()
            update_spinner()

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
            local valid_items = {}
            for _, item in ipairs(qflist) do
                if item.valid == 1 then table.insert(valid_items, item) end
            end

            -- Keep quickfix entries navigable. Build-system status lines such as
            -- FAILED and ninja output have no source location.
            if source_only and #valid_items ~= #qflist then
                vim.fn.setqflist({}, " ", { title = cmd, items = valid_items })
            end
            local valid_errors = #valid_items

            if valid_errors > 0 then
                if exit_code ~= 0 then
                    vim.g.async_make_status = string.format(
                        '[Build failed: %d alerts (%s)]', valid_errors, duration)
                else
                    vim.g.async_make_status = string.format('[%d alerts (%s)]', valid_errors, duration)
                end
                vim.cmd("copen")
                -- Jump to first error if the build failed
                if exit_code ~= 0 then
                    pcall(vim.cmd, "cfirst")
                end
            elseif exit_code ~= 0 then
                -- Build failed but no matches found in output
                vim.g.async_make_status = string.format('[Failed (%s)]', duration)
                vim.cmd("copen")
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

-- Watch for builds started outside this Neovim instance in the same directory.
function M.setup()
    refresh_notify_state()

    if not M.ui.watch_augroup then
        M.ui.watch_augroup = vim.api.nvim_create_augroup("AsyncMakeWatcher", { clear = true })
        vim.api.nvim_create_autocmd("DirChanged", {
            group = M.ui.watch_augroup,
            callback = refresh_notify_state,
        })
    end

    if M.ui.watch_timer then return end

    M.ui.watch_timer = vim.uv.new_timer()
    M.ui.watch_timer:start(0, 500, vim.schedule_wrap(function()
        if not M.current_job then
            M.ui.external_active = external_build_active()
        end
        update_spinner()
    end))
end

return M

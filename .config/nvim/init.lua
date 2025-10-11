-- Load regular VIM-compatible settings file.
vim.cmd("source ~/.config/nvim/viml/init.vim")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

 -- Make sure to set `mapleader` before Lazy setup so your mappings are correct.
vim.g.mapleader = " "

vim.g.async_make_status = ""

-- Show highlight for yanked regions
vim.cmd[[
    augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank
        \ { higroup=(vim.fn["hlexists"]("HighlightedyankRegion") > 0 and
        \ "HighlightedyankRegion" or "IncSearch"), timeout=500 }
    augroup END
]]

function QuickfixJump(direction)
    local info = vim.fn.getqflist({ idx = 0, items = 0 })
    local total = #info.items
    local current = info.idx

    if total == 0 then
        print("Quickfix list is empty")
        return
    elseif total == 1 then
        vim.cmd("cc 1")
        vim.api.nvim_command("normal! zz")
        return
    end

    local new_index = ((current - 1 + direction) % total) + 1
    vim.cmd("cc " .. new_index)
    vim.api.nvim_command("normal! zz")
end

function ShowVisualCharCount()
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))
  local count

  if ls == le then
    local line_content = vim.fn.getline(ls)
    count = #string.sub(line_content, cs, ce)
  else
    local lines = vim.fn.getline(ls, le)
    lines[#lines] = string.sub(lines[#lines], 1, ce)
    lines[1] = string.sub(lines[1], cs)
    local text = table.concat(lines, "\n")
    count = #text
  end

  print("Selection length: " .. count .. " characters")
end

vim.api.nvim_set_keymap('v', '<leader>vc', [[:lua ShowVisualCharCount()<CR>]], { noremap = true, silent = true })

-- Set up key mappings for quickfix navigation.
vim.api.nvim_set_keymap("n", "]q", ":lua QuickfixJump(1)<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "[q", ":lua QuickfixJump(-1)<CR>", { noremap = true, silent = true })

local function generate_and_execute_sed_command(args)
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    local file_path = vim.fn.shellescape(vim.fn.expand("%:p"))
    if file_path == "" then
        print("Buffer does not have a file path.")
        return
    end

    local sed_command = string.format("sed -n '%d,%dp' %s", start_line, end_line, file_path)
    print(sed_command)

    local output = vim.fn.system(sed_command)

    if args.args == "buffer" then
        vim.cmd("new") -- Open a new split
        vim.cmd("setlocal buftype=nofile") -- Make the buffer a scratch buffer
        vim.cmd("setlocal bufhidden=wipe") -- Wipe the buffer when closed
        vim.cmd("setlocal noswapfile") -- Disable swapfile for this buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
    else
        print(output)
    end
end

vim.api.nvim_create_user_command(
    "SedDump",
    generate_and_execute_sed_command,
    {
        range = true,
        nargs = "?",
        desc = "Generate and execute sed command based on visual selection (optionally output to buffer)"
    }
)

-- Copy line/visual block then comment it out and paste below.
vim.keymap.set('n', 'yc', 'yy<cmd>normal gcc<CR>p')
vim.keymap.set('v', 'Yc', 'y<cmd>normal gvgc<CR>o<Esc>p')

vim.g.zig_syntax_disable = true

local function trim_trailing_whitespace()
  local save_cursor = vim.fn.getpos('.')
  local file_path = vim.api.nvim_buf_get_name(0)
  local git_dir = vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null')
  local is_tracked = vim.fn.system('git ls-files --error-unmatch -- ' .. file_path .. ' 2>/dev/null')

  if git_dir and vim.fn.trim(is_tracked) == '' then
      -- Untracked file, trim all trailing whitespace
      vim.cmd('%s/\\s\\+$//e')
      vim.fn.setpos('.', save_cursor)
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = trim_trailing_whitespace,
  group = vim.api.nvim_create_augroup('TrimWhitespace', { clear = true }),
})

-- Plugins
require("lazy").setup({
    {
        -- Load colorscheme first.
        "ellisonleao/gruvbox.nvim",
        disable = true,
        lazy = false,
        priority = 1000,
        init = function()
            vim.cmd("colorscheme gruvbox")
        end
    },
    {
        "neanias/everforest-nvim",
        version = false,
        lazy = false,
        priority = 1000,
        config = function()
            local everforest = require("everforest")
            everforest.setup({
                float_style = "dim",
                background = "hard",
                italics = true,
                -- transparent_background_level = 0,
                -- disable_italic_comments = false
                on_highlights = function(hl, palette)
                    local float_bg = palette.bg0
                    local border_fg = palette.grey2
                    hl.BlinkCmpMenu = { bg = float_bg }
                    hl.BlinkCmpMenuBorder = { bg = float_bg, fg = border_fg }
                    hl.BlinkCmpDoc = { bg = float_bg }
                    hl.BlinkCmpDocBorder = { bg = float_bg, fg = border_fg }

                    hl.TreesitterContext = { bg = palette.bg2 }

                    hl.FzfLuaBorder = { bg = "#121517", fg = border_fg }
                    -- hl.FzfLuaTitle = { bg = "#121517", fg = border_fg }
                end,
                colours_override = function (palette)
                    -- hard-er
                    -- source: <https://gist.github.com/suppayami/7d427d116b97564d1c565a7aed092d08>
                    palette.bg0 = "#1E2327" -- replaces bg0 = "#272e33",
                end
            })
            everforest.load()
        end,
    },
    {
        -- Diplay hexcode colours directly in editor.
        "norcalli/nvim-colorizer.lua",
        cmd = {
            "ColorizerAttachToBuffer",
            "ColorizerDetachFromBuffer",
        },
    },
    {
        -- Trailing cursor
        -- :SmearCursorToggle
        "sphamba/smear-cursor.nvim",
        opts = {
            smear_between_buffers = true,
            smear_between_neighbor_lines = false,
        },
    },
    {
        -- Status bar customization.
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local function build_status()
                return vim.g.async_make_status
            end

            require("lualine").setup({
                sections = {
                    lualine_c = {
                        {
                            'filename',
                            file_status    = true,
                            newfile_status = false,
                            path           = 1,
                            shorting_target = 40,
                            symbols = {
                                modified = '[+]',
                                readonly = '[-]',
                                unnamed  = '[No Name]',
                                newfile  = '[New]',
                            },
                        },
                    },
                    lualine_x = {
                        { build_status },
                        "%{ObsessionStatus()}",
                        "encoding",
                        "fileformat",
                        "filetype",
                    },
                },
            })
        end
    },
    {
        -- Nicer tabs.
        'nanozuki/tabby.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            local theme = {
                fill = 'TabLineFill',
                -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
                head = 'TabLine',
                current_tab = 'TabLineSel',
                tab = 'TabLine',
                win = 'TabLine',
                tail = 'TabLine',
            }
            require('tabby').setup({
                line = function(line)
                    return {
                        {
                            -- TODO: need better way to refer to current colorscheme values instead of manual hardcode
                            { '  ', hl = { fg = '#7FBBB3', bg = '#414B50' } },
                            line.sep('', theme.head, theme.fill),
                        },
                        line.tabs().foreach(function(tab)
                            local hl = tab.is_current() and theme.current_tab or theme.tab
                            local fg = (hl == theme.tab and '#9da9a0') or (hl == theme.current_tab and '#1e2327')
                            local bg = (hl == theme.tab and '#414b50') or (hl == theme.current_tab and '#a7c080')

                            -- remove count of wins in tab with [n+] included in tab.name()
                            local name = tab.name()
                            local index = string.find(name, "%[%d")
                            local tab_name = index and string.sub(name, 1, index - 1) or name

                            -- indicate if any of buffers in tab have unsaved changes
                            local win_is_modified = function(win)
                                return vim.bo[win.buf().id].modified
                            end
                            local modified = false
                            tab.wins().foreach(function(win)
                                if win_is_modified(win) then
                                    modified = true
                                    return
                                end
                            end)

                            return {
                                line.sep('', hl, theme.fill),
                                tab.number(),
                                { tab_name, hl = modified and { fg = fg, bg = bg, style = 'italic' } or hl },
                                modified and '',
                                tab.close_btn(''),
                                line.sep('', hl, theme.fill),
                                hl = hl,
                                margin = ' ',
                            }
                        end),
                        line.spacer(),
                        {
                            line.sep('', theme.tail, theme.fill),
                            { '  ', hl = theme.tail },
                        },
                        hl = theme.fill,
                    }
                end,
            })
        end,
    },
    {
        -- For unifying TMUX pane / VIM split navigation.
        'mrjones2014/smart-splits.nvim',
        dependencies = {
            {
                "kwkarlwang/bufresize.nvim",
                config = function()
                    require("bufresize").setup()
                end
            },
        },
        config = function ()
            require("smart-splits").setup({
                default_amount = 5,
                cursor_follows_swapped_bufs = true,
                at_edge = function (ctx)
                    if ctx.mux.type == "tmux" and ctx.mux.current_pane_is_zoomed() then
                        return "stop"
                    else
                        return "wrap"
                    end
                end,
                resize_mode = {
                    hooks = {
                        on_leave = require('bufresize').register,
                    },
                },
            })
            -- moving between splits: ALT+<hjkl>
            vim.keymap.set('n', '<M-h>', require('smart-splits').move_cursor_left)
            vim.keymap.set('n', '<M-j>', require('smart-splits').move_cursor_down)
            vim.keymap.set('n', '<M-k>', require('smart-splits').move_cursor_up)
            vim.keymap.set('n', '<M-l>', require('smart-splits').move_cursor_right)
            vim.keymap.set('n', '<M-\\>', require('smart-splits').move_cursor_previous)
            -- resizing splits: ALT+<HJKL>
            vim.keymap.set('n', '<M-S-h>', require('smart-splits').resize_left)
            vim.keymap.set('n', '<M-S-j>', require('smart-splits').resize_down)
            vim.keymap.set('n', '<M-S-k>', require('smart-splits').resize_up)
            vim.keymap.set('n', '<M-S-l>', require('smart-splits').resize_right)
        end
    },
    {
        -- For saving editor state (windows/tabs/layout) to a session file.
        -- Save with command: :Obsession <path-to-save-to>
        -- Load with:         nvim -S <path-to-session-file>
        "tpope/vim-obsession"
    },
    {
        -- The greatest search plugin ever!!!
        "ibhagwan/fzf-lua",
        opts = {
            oldfiles = {
                include_current_session = true,
            },
            previewers = {
                builtin = {
                    syntax_limit_b = 1024 * 200, -- 100KB
                },
            },
            grep = {
                -- TODO: idk about this but I saw it online
                --
                -- Ex: Find all occurrences of "enable" but only in the "plugins" directory.
                -- With this change, I can sort of get the same behaviour in live_grep.
                -- ex: > enable --*/plugins/*
                -- I still find this a bit cumbersome. There's probably a better way of doing this.
                rg_glob = true, -- enable glob parsing
                glob_flag = "--iglob", -- case insensitive globs
                glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
            },
        },
        keys = {
            {"<C-p>", "<cmd>FzfLua git_files<cr>", desc = "FZF git files"},
            {"<leader>ff", "<cmd>FzfLua files<cr>", desc = "FZF files"},
            {"<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "FZF recent files"},
            {"<leader>/", "<cmd>FzfLua grep_cword<cr>", desc = "FZF word under cursor"},
            {"<leader>L", "<cmd>FzfLua resume<cr>", desc = "FZF resume last search"},
            {"<leader>?", "<cmd>FzfLua grep<cr>", desc = "FZF search"},
            {"<leader><space>", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
            {"<leader>l", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
            {"<leader>c", "<cmd>FzfLua commands<cr>", desc = "FZF commands"},
            {"<leader>s", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "LSP Document Symbols"},
            {"<leader>of", "<cmd>lua require'fzf-lua'.files({ prompt='orgfiles> ', cwd='~/orgfiles' })<cr>", desc = "FZF Org Files"},
        },
    },
    {
        -- File explorer as regular buffer.
        "stevearc/oil.nvim",
        ---@module 'oil'
        ---@type oil.SetupOpts
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            columns = {
                "icon",
                "permissions",
                "size",
                "mtime",
            },
            view_options = {
                show_hidden = true,
            },
            float = {
                -- Padding around the floating window
                padding = 10,
                max_width = 0,
                max_height = 0,
                border = "rounded",
                win_options = {
                    winblend = 0,
                },
            },
            keymaps = {
                ["<C-h>"] = { "actions.toggle_hidden", mode = "n" },
                ["<Esc>"] = { "actions.close", mode = "n" },
            }
        },
        keys = {
            {"<leader>e", vim.cmd.Oil, desc = "Open Oil in a buffer"},
            {"<leader>E", "<cmd>Oil --float<CR>", desc = "Open Oil in a floating window"},
        },
    },
    -- Organize your life.
    --      <leader>oa = open agenda file.
    --      <leader>oc = open notes file (to be re-filed).
    {
        'nvim-orgmode/orgmode',
        dependencies = {
            {
                "nvim-orgmode/org-bullets.nvim",
                config = function()
                    require('org-bullets').setup()
                end,
            }
        },
        event = 'VeryLazy',
        ft = { 'org' },
        config = function()
            require('orgmode').setup({
                org_agenda_files = '~/orgfiles/**/*',
                org_default_notes_file = '~/orgfiles/refile.org',
                org_adapt_indentation = false,
            })

            require('nvim-treesitter.configs').setup({
                  ignore_install = { 'org' },
            })
        end,
    },
    {
        "chipsenkbeil/org-roam.nvim",
        tag = "0.1.1",
        dependencies = {
            {
                "nvim-orgmode/orgmode",
                tag = "0.3.7",
            },
        },
        event = 'VeryLazy',
        ft = { 'org' },
        config = function()
            require("org-roam").setup({
                directory = "~/orgfiles",
                -- optional
                -- org_files = {
                --     "~/another_org_dir",
                --     "~/some/folder/*.org",
                --     "~/a/single/org_file.org",
                -- }
            })
        end
    },
    {
        -- Add git commands directly in the editor.
        --
        -- Some favourite commands (there's so much more...):
        --     :Git (:G for short)  - open git summary/status window
        --     :G blame             - open in-line blame of current buffer
        --     :G diff              - open split with `git diff` output
        --     :0G diff             - open full buffer to `git diff` output
        --
        -- TODO: find a solution so git plugins can be utilized with bare repo
        -- workaround by invoking nvim with explicit env var:
        --   GIT_DIR=$HOME/.dotfiles GIT_WORK_TREE=$HOME nvim .config/nvim/init.lua
        "tpope/vim-fugitive",
    },
    {
        -- Incredibly powerful single tabpage interface for easily cyclingthrough
        -- through diffs for all modified files for any git rev.
        --
        --      :DiffviewOpen HEAD~1            - current unstaged changes
        --      :DiffviewOpen d695eca^!         - view specific revision changes
        --      :DiffviewFileHistory            - history for current branch
        --      :DiffviewFileHistory %          - history for current file
        --      :DiffviewOpen <rev_a>...<rev_b> - between two revisions
        --      :h diffview-merge-tool          - powerful merge tool too (haven't tried it)
        "sindrets/diffview.nvim",
    },
    {
        -- Git gutter display.
        "lewis6991/gitsigns.nvim",
        lazy = false,
        config = function()
            local function trim_trailing_whitespace_git(bufnr)
                local gs = package.loaded.gitsigns
                if not gs then return end -- Gitsigns not loaded, do nothing

                local hunks = gs.get_hunks(bufnr)
                if not hunks or #hunks == 0 then return end -- No hunks, do nothing

                local save_cursor = vim.fn.getpos('.')

                for _, hunk in ipairs(hunks) do
                    if hunk.type == 'add' or hunk.type == 'change' then
                        for line_num = hunk.added.start, hunk.added.start + hunk.added.count - 1 do
                            local line = vim.fn.getline(line_num)
                            local new_line = string.gsub(line, '%s+$', '')
                            if new_line ~= line then
                                vim.fn.setline(line_num, new_line)
                            end
                        end
                    end
                end

                vim.fn.setpos('.', save_cursor)
            end

            require("gitsigns").setup({
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                    end, {expr=true})

                    map('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                    end, {expr=true})

                    -- Actions
                    map('n', '<leader>hs', gs.stage_hunk)
                    map('n', '<leader>hr', gs.reset_hunk)
                    map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
                    map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
                    map('n', '<leader>hS', gs.stage_buffer)
                    map('n', '<leader>hu', gs.undo_stage_hunk)
                    map('n', '<leader>hR', gs.reset_buffer)
                    map('n', '<leader>hp', gs.preview_hunk)
                    map('n', '<leader>hb', function() gs.blame_line{full=true} end)
                    map('n', '<leader>tb', gs.toggle_current_line_blame)
                    map('n', '<leader>hd', gs.diffthis)
                    map('n', '<leader>hD', function() gs.diffthis('~') end)
                    map('n', '<leader>td', gs.toggle_deleted)

                    -- Text object
                    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')

                    vim.api.nvim_create_autocmd('BufWritePre', {
                        buffer = bufnr,
                        callback = function()
                            trim_trailing_whitespace_git(bufnr)
                        end,
                        group = vim.api.nvim_create_augroup('TrimWhitespaceGit', { clear = true }),
                    })
                end
            })
        end,
        keys = {
            { '<leader>G', '<cmd>lua require"gitsigns".setqflist("all")<CR>', desc = 'Set qflist to unstaged changes' },
        }

    },
    {
        -- Multiple search highlights - great for log analysis.
        --      f<enter>   - add higlight for word/selection
        --      f<delete>  - remove highlighted word/selection
        --      alt+n      - go next highlight
        --      alt+N      - go prev highlight
        "azabiong/vim-highlighter",
        lazy = false,
        keys = {
            -- highlights across window splits :Hi ==
            -- hightlights only in current window  :Hi =
            {"<M-n>", "<cmd>Hi}<cr>", desc = "Highlighter next recent"},
            {"<M-N>", "<cmd>Hi{<cr>", desc = "Highlighter prev recent"},
            {"<leader>}", "<cmd>Hi><cr>", desc = "Highlighter next any"},
            {"<leader>{", "<cmd>Hi<<cr>", desc = "Highlighter prev any"},
            {"<leader>H", "<cmd>Hi clear<<cr>", desc = "Highlighter prev any"},
        },
        init = function()
            vim.cmd([[
                " synchronize across all tabs and windows
                let HiSyncMode = 2
                " :Hi/Find  [options]  expression  [directories_or_files]
                let HiFindTool = 'rg -H --color=never --no-heading --column'
            ]])
        end
    },
    {
        -- CTRL + / to toggle comments in normal/visual mode.
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
            local opts = { remap = true, silent = true }
            vim.keymap.set("n", "<C-_>", "gcc", opts)
            vim.keymap.set("v", "<C-_>", "gc", opts)
        end
    },
    {
        -- Displays filename on each split in floating in top right.
        -- reference: https://github.com/b0o/incline.nvim/discussions/75
        'b0o/incline.nvim',
        event = 'VeryLazy',
        keys = {
            { '<leader>I', '<cmd>lua require"incline".toggle()<CR>', desc = 'Incline: Toggle' },
        },
        config = function()
            require('incline').setup({
                hide = {
                    cursorline = 'focused_win',
                    only_win = true,
                },
                window = {
                    margin = {
                        horizontal = 0,
                        vertical = 1,
                    },
                    overlap = {
                        borders = true,
                        statusline = false,
                        tabline = true,
                        winbar = false
                    },
                    padding = 1,
                    padding_char = " ",
                    placement = {
                        horizontal = "right",
                        vertical = "top"
                    },
                    width = "fit",
                    winhighlight = {
                        active = {
                            Normal = "TSTodo",
                        },
                    },
                },
                ignore = {
                    unlisted_buffers = false,
                    floating_wins = false,
                    buftypes = function(bufnr, buftype)
                        return not (
                        buftype == ''
                        or buftype == 'help'
                        or buftype == 'quickfix'
                        or vim.bo[bufnr].filetype == 'dap-repl'
                        or vim.bo[bufnr].filetype == 'dapui_scopes'
                        or vim.bo[bufnr].filetype == 'dapui_breakpoints'
                        or vim.bo[bufnr].filetype == 'dapui_stacks'
                        or vim.bo[bufnr].filetype == 'dapui_watches'
                        or vim.bo[bufnr].filetype == 'dapui_console'
                        )
                    end,
                    wintypes = function(winid, wintype)
                        local zen_view = package.loaded['zen-mode.view']
                        if zen_view and zen_view.is_open() then
                            return winid ~= zen_view.win
                        end
                        return not (wintype == '' or wintype == 'quickfix' or wintype == 'loclist')
                    end,
                },
            })
        end,
    },
    {
        -- Scroll past top for a screen-centered view.
        'nullromo/go-up.nvim',
        opts = {}, -- specify options here
        config = function(_, opts)
            local goUp = require('go-up')
            goUp.setup(opts)
        end,
    },
    {
        -- Declutter visuals and just focus on one buffer.
        "folke/zen-mode.nvim",
        opts = {
            window = {
                width = 0.7
            },
            plugins = {
                -- disable some global vim options (vim.o...)
                -- comment the lines to not apply the options
                options = {
                    enabled = true,
                    ruler = false, -- disables the ruler text in the cmd line area
                    showcmd = false, -- disables the command in the last line of the screen
                    -- you may turn on/off statusline in zen mode by setting 'laststatus'
                    -- statusline will be shown only if 'laststatus' == 3
                    laststatus = 0, -- turn off the statusline in zen mode
                },
                gitsigns = { enabled = false }, -- disables git signs
                tmux = { enabled = false }, -- disables the tmux statusline
            },
            on_open = function(_)
                vim.fn.system([[tmux set status off]])
                vim.fn.system(
                [[tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z]])
            end,
            on_close = function(_)
                vim.fn.system([[tmux set status on]])
            end
        },
        keys = {
            {"<leader>Z", "<cmd>ZenMode<cr>", desc = "ZenMode"},
        }
    },
    {
        -- Modify surrounding delimiter pairs more easily. Reference (because I always forget...):
        --
        --  Before Text                 Command         After text
        --  ------------------------------------------------------------------
        --  surr*ound_words             ysiw)           (surround_words)
        --  *make strings               ys$"            "make strings"
        --  [delete ar*ound me!]        ds]             delete around me!
        --  remove <b>HTML t*ags</b>    dst             remove HTML tags
        --  'change quot*es'            cs'"            "change quotes"
        --  <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
        --  delete(functi*on calls)     dsf             function calls
        --
        --  And the most useful: with visual selection |<selected>|:
        --  local str = |some text|     S'              local str = 'some text'
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup()
        end
    },
    {
        -- Add closing delimiter automatically.
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
    {
        -- Move line/visual selection of text up/down with ctrl+shift+<up/down>.
        -- Works in normal, visual, and insert modes, with indent-awareness.
        "fedepujol/move.nvim",
        keys = {
            { "<C-Down>", ":MoveLine(1)<CR>", mode = { "n" } },
            { "<C-Up>", ":MoveLine(-1)<CR>", mode = { "n" } },
            { "<C-Down>", ":MoveBlock(1)<CR>", mode = { "v" } },
            { "<C-Up>", ":MoveBlock(-1)<CR>", mode = { "v" } },
            { "<C-Down>", "<C-\\><C-N>:MoveLine(1)<CR>i", mode = { "i" } },
            { "<C-Up>", "<C-\\><C-N>:MoveLine(-1)<CR>i", mode = { "i" } },
        },
        config = function()
            require("move").setup({})
        end
    },
    {
        -- Navigate by eye.
        -- 's' becomes search forward
        -- 'S' becomes search backwards
        "ggandor/leap.nvim",
        config = function()
            vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
            vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
            vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
        end,
    },
    {
        -- Highlight word under cursor.
        'tzachar/local-highlight.nvim',
        config = function()
            require('local-highlight').setup({
                -- disable_file_types = {'tex'},
                hlgroup = 'Visual',
                cw_hlgroup = nil, -- highlight under cursor
                insert_mode = false,
                -- fix startup error? requires snacks.nvim
                animate = {
                    enabled = false,
                }
            })

            vim.opt.updatetime = 400
        end
    },
    {
        "folke/lazydev.nvim",
        ft = "lua", -- Only load for Lua files
        opts = {
            library = {
                -- Optional: Add paths for third-party libraries if needed (e.g., luv for vim.uv)
                -- { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        -- Some basic default client configuration setings for NVIM LSP.
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "saghen/blink.cmp"
            },
        },
    },
    {
        -- Solves the terrible native lsp inlay hint behaviour.
        -- * useful command to toggle inlay hint native display
        --   :lua require("lsp-endhints").toggle()
        "chrisgrieser/nvim-lsp-endhints",
        event = "LspAttach",
        opts = {}, -- required, even if empty
        init = function()
            require("lsp-endhints").setup({
                icons = {
                    type = "=> ",
                    parameter = "<- ",
                },
            })
        end
    },
    {
        'saghen/blink.compat',
        version = '*',
        lazy = true,
        opts = {},
    },
    {
        -- Autocompletion.
        'saghen/blink.cmp',
        dependencies = {
            {'rafamadriz/friendly-snippets'},
            { 'L3MON4D3/LuaSnip', version = 'v2.*' },
        },
        version = '*',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                ['<Tab>'] = {
                    function(cmp)
                        if cmp.snippet_active() then
                            return cmp.snippet_forward()
                        end
                        if cmp.is_visible() then
                            return cmp.select_next()
                        end
                    end,
                    'fallback'
                },
                ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
                ['<C-y>'] = { 'accept', 'fallback' },
                ['<CR>'] = { 'accept', 'fallback' },
                ['<C-l>'] = { 'show', 'hide', 'fallback' },
                ['<C-e>'] = { 'cancel', 'fallback' },
                ['<C-Space>'] = { 'show_documentation', 'hide_documentation', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
            },
            completion = {
                list = { selection = { preselect = false, auto_insert = true } },
                accept = { auto_brackets = { enabled = false } },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 0,
                },
                menu = {
                    draw = { columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } } },
                },
            },
            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono'
            },
            snippets = {
                preset = 'luasnip',
            },
            signature = {
                enabled = true,
            },
            sources = {
                default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,  -- Prioritize lazydev completions
                    },
                },
            },
        },
        opts_extend = { "sources.default" }
    },
    {
        -- Package manager for Neovim, installs LSP/DAP/Lint servers automatically.
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        cmd = {
            "Mason",
            "MasonInstall",
            "MasonUninstall",
            "MasonUninstallAll",
            "MasonLog",
        },
        dependencies = {
            "neovim/nvim-lspconfig",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "mfussenegger/nvim-dap",
            "jay-babu/mason-nvim-dap.nvim",
        },
        config = function()
            vim.lsp.config('lua_ls', {
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = {
                            globals = { 'vim' },
                        },
                        workspace = {
                            checkThirdParty = false,
                        },
                        telemetry = {
                            enable = false,
                        },
                    },
                },
            })

            vim.lsp.config('pylsp', {
                settings = {
                    pylsp = {
                        plugins = {
                            pycodestyle = {
                                maxLineLength = 100,
                            },
                        },
                    },
                },
            })

            vim.lsp.config('zls', {
                settings = {
                    zls = {
                        build_runner = "build",
                        build_step = "check",
                    },
                },
            })

            local mason = require("mason")
            local mason_lspconfig = require("mason-lspconfig")
            local mason_tool_installer = require("mason-tool-installer")

            -- Enable Mason.
            mason.setup({
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })

            -- Bridge Mason with lspconfig.
            mason_lspconfig.setup({
                ensure_installed = {
                    "bashls",
                    "clangd",
                    "dockerls",
                    "lua_ls",
                    "pylsp",
                    "zls",
                },
            })

            -- Setup for formatters, linters, and debug adapters.
            mason_tool_installer.setup({
                ensure_installed = {
                    -- Formatters and Linters
                    "cmakelang", -- CMake
                    "markdownlint", --Markdown

                    -- Linters
                    -- "pylint", -- Python
                    -- "luacheck", -- Lua

                    -- Debugger adapters
                    "bash-debug-adapter", -- Shell
                    "codelldb", -- C/C++/Rust
                    "cpptools",
                    -- "debugpy", -- Python
                },
            })
        end,
    },
    {
        -- Configures rust-analyzer builtin LSP client + integrates with other Rust tools.
        -- https://github.com/mrcjkb/rustaceanvim/discussions/122
        'mrcjkb/rustaceanvim',
        version = '^6', -- Recommended
        ft = { 'rust' },
        lazy = false,
        init = function()
            vim.g.rustaceanvim = {
                -- Plugin configuration
                tools = {
                    autoSetHints = true,
                    -- the neovim 0.10 native inlay hints kind of suck...
                    -- https://github.com/neovim/neovim/issues/28261
                    inlay_hints = {
                        show_parameter_hints = true,
                        parameter_hints_prefix = "<- ",
                        other_hints_prefix = "=> ",
                    },
                    float_win_config = {
                        border = 'rounded',
                    }
                },
                -- LSP configuration
                server = {
                    on_attach = function(client, bufnr)
                        -- mappings(client, bufnr)
                        -- require("illuminate").on_attach(client)

                        local bufopts = {
                            noremap = true,
                            silent = true,
                            buffer = bufnr
                        }
                        vim.keymap.set('n', '<leader>A', "<Cmd>RustLsp codeAction<CR>", bufopts)
                        vim.keymap.set('n', '<leader>a', "<Cmd>RustLsp hover actions<CR>", bufopts)
                        vim.keymap.set('n', 'K', "<Cmd>RustLsp hover actions<CR>", bufopts)
                    end,
                    settings = {
                        -- rust-analyzer language server configuration
                        ['rust-analyzer'] = {
                            -- assist = {
                            --     importEnforceGranularity = true,
                            --     importPrefix = "create"
                            -- },
                            cargo = {
                                allFeatures = true,
                                loadOutDirsFromCheck = true,
                                runBuildScripts = true,
                            },
                            -- checkOnSave = {
                            --     -- default: `cargo check`
                            --     command = "clippy",
                            --     allFeatures = true,
                            --     extraArgs = { "--no-deps" },
                            -- },
                            -- inlayHints = {
                            --     lifetimeElisionHints = {
                            --         enable = true,
                            --         useParameterNames = true
                            --     }
                            -- }
                        }
                    }
                },
                dap = {},
            }
            -- workaround fix for error: "LSP: rust_analyzer: -32802: server cancelled the request"
            -- https://github.com/neovim/neovim/issues/30985
            for _, method in ipairs({ 'textDocument/diagnostic', 'workspace/diagnostic' }) do
                local default_diagnostic_handler = vim.lsp.handlers[method]
                vim.lsp.handlers[method] = function(err, result, context, config)
                    if err ~= nil and err.code == -32802 then
                        return
                    end
                    return default_diagnostic_handler(err, result, context, config)
                end
            end
         end
    },
    {
        'ziglang/zig.vim',
        lazy = true,
        ft = { 'zig' }
    },
    {
        -- Provide much better syntax highlighting + dynamic code presentations
        -- based on cursor position and scope.
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPre" },
        cmd = { "TSInstall", "TSUpdate" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            "RRethy/nvim-treesitter-textsubjects",
            {
                "nvim-treesitter/nvim-treesitter-context",
                config = function()
                    require("treesitter-context").setup({
                        -- :TSContextToggle
                        max_lines = 10, -- How many lines the window should span. Values <= 0 mean no limit.
                        min_window_height = 30, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                        line_numbers = true,
                        multiline_threshold = 10, -- Maximum number of lines to show for a single context
                        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                        mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
                        zindex = 20, -- The Z-index of the context window
                    })
                end
            },
        },
        config = function()
            -- TODO: how to suppress big error '------' that shows up when opening ft
            -- without a treesitter installed?
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "c",
                    "cpp",
                    "bash",
                    "git_config",
                    "git_rebase",
                    "gitattributes",
                    "gitcommit",
                    "gitignore",
                    "ssh_config",
                    "diff",
                    "lua",
                    "vim",
                    "vimdoc",
                    "query",
                    "rust",
                    "make",
                    "markdown",
                    "markdown_inline",
                    "python",
                    "meson",
                    "zig",
                    "toml",
                    "tmux",
                },
                with_sync = true,
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,
                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = false,
                ignore_install = {},
                modules = {},
                highlight = {
                    enable = true,
                    disable = function(_, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
            })

            -- Folding keybinds:
            -- * zR: open all folds
            -- * zM: close all folds
            -- * za: toggle fold at cursor
            -- * zA: toggle fold and its children at curso
            -- * zj: move to next fold
            -- * zk: move to prev fold

            -- Folding configuration directly inside config
            local function setup_folding()
                -- Default to Treesitter folding
                vim.opt.foldmethod = "expr"
                vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
                vim.opt.foldcolumn = "0"
                vim.opt.foldlevel = 99
                vim.opt.foldtext = ""
                vim.opt.foldnestmax = 4
                vim.opt.foldlevelstart = 99

                -- Function to check if LSP provides folding and set it up
                local function setup_lsp_folding(client, bufnr)
                    if client.server_capabilities.foldingRangeProvider then
                        vim.api.nvim_buf_set_option(bufnr, "foldmethod", "expr")
                        vim.api.nvim_buf_set_option(bufnr, "foldexpr", "nvim_treesitter#foldexpr()")
                    end
                end

                -- Setup LSP folding on attach
                vim.api.nvim_create_autocmd("LspAttach", {
                    callback = function(args)
                        local client = vim.lsp.get_client_by_id(args.data.client_id)
                        setup_lsp_folding(client, args.buf)
                    end,
                })

                -- Revert to syntax folding if no tree sitter.
                vim.api.nvim_create_autocmd({ "FileType" }, {
                    callback = function()
                        if require("nvim-treesitter.parsers").has_parser() then
                            vim.opt.foldmethod = "expr"
                            vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
                        else
                            vim.opt.foldmethod = "syntax"
                        end
                    end,
                })

            end

            setup_folding()
        end,
    },
    {
        -- Visual plugin to better display indentation level and current scope.
        "lukas-reineke/indent-blankline.nvim",
        event = "BufReadPost",
        main = "ibl",
        ---@module "ibl"
        ---@type ibl.config
        opts = {
            -- NOTE: "scope" here refers to variable accessibitily, NOT the
            -- current cursor indentation level
            -- scope = { enabled = true },
            -- TODO: await "current_indent" PR, which is what I liked from v2
            -- https://github.com/lukas-reineke/indent-blankline.nvim/pull/743
            exclude = {
                filetypes = { "help", "alpha", "dashboard", "Trouble",
                              "lazy", "neo-tree", "dap.*", "NvimTree" },
                buftypes = { "terminal", "prompt", "nofile" },
            },
        },
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons'
        },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    },
    {
        -- Interactive debugging in-editor.
        --      <leader>b    - set breakpoint
        --      <leader>B    - set conditional breakpoint
        --      <leader>;    - evaluate variable under cursor
        --      <leader>gb   - continue until cursor
        --      F1           - continue
        --      F2           - step Into
        --      F3           - step Over
        --      F4           - step Out
        --      F5           - step backward (only for RR?)
        --      F6           - up call stack
        --      F7           - down call stack
        --      F10          - restart debugging
        --
        -- NOTE: you can execute GDB commands in the DAP-REPL window with `-exec` prefix
        -- -exec p/x cur
        -- $2 = 0x7fffd96ef052
        -- -exec x /s 0x7fffffffbf90
        -- 0x7fffffffbf90: "PUT /testcontainer1/iiiiiiii@!~`#$%^一&&()_+;'.,OOOOOO.docx?_=1734978413389 HTTP/1.1"
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                opts = {
                    layouts = { {
                        elements = { {
                            id = "scopes",
                            size = 0.35
                        }, {
                            id = "breakpoints",
                            size = 0.15
                        }, {
                            id = "stacks",
                            size = 0.25
                        }, {
                            id = "watches",
                            size = 0.25
                        } },
                        position = "left",
                        size = 80
                    }, {
                        elements = { {
                            id = "repl",
                            size = 0.5
                        }, {
                            id = "console",
                            size = 0.5
                        } },
                        position = "bottom",
                        size = 15
                    } },
                },
                config = function(_, opts)
                    require("dapui").setup(opts)
                    require("nvim-dap-virtual-text").setup({})
                end,
                dependencies = {
                    "theHamsta/nvim-dap-virtual-text",
                }
            },
            "nvim-neotest/nvim-nio",
            "williamboman/mason.nvim",
        },
        config = function()
            local dap = require("dap")
            local ui = require("dapui")

            -- Insert a conditional breakpoint. e.g.:
            -- :DapConditional "foo > 10"
            vim.api.nvim_create_user_command('DapConditional', function(args)
                local condition = args.args:match('^[\'"](.*)[\'"]$') or args.args
                dap.toggle_breakpoint(condition)
            end, { nargs = 1 })

            vim.keymap.set("n", "<leader>gb", dap.run_to_cursor)
            vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
            vim.keymap.set("n", "<leader>B", function()
                local condition = vim.fn.input("Enter condition: ")
                if condition == nil then
                    return
                end

                local cmd_arg = string.format("%q", condition)
                vim.cmd("DapConditional " .. cmd_arg)
            end, { desc = "Set conditional breakpoint" })

            -- Eval variable under cursor.
            vim.keymap.set("n", "<leader>;", function()
                ui.eval(nil, { enter = true })
            end)

            vim.keymap.set("n", "<F1>", dap.continue)
            vim.keymap.set("n", "<F2>", dap.step_into)
            vim.keymap.set("n", "<F3>", dap.step_over)
            vim.keymap.set("n", "<F4>", dap.step_out)
            vim.keymap.set("n", "<F5>", dap.step_back) -- only for rr?

            vim.keymap.set('n', '<F6>', dap.up)
            vim.keymap.set('n', '<F7>', dap.down)

            vim.keymap.set("n", "<F10>", dap.restart)

            dap.listeners.before.attach.dapui_config = function() ui.open() end
            dap.listeners.before.launch.dapui_config = function() ui.open() end
            dap.listeners.before.event_terminated.dapui_config = function() ui.close() end
            dap.listeners.before.event_exited.dapui_config = function() ui.close() end

            -- Fixup DAP UI after window resize.
            vim.api.nvim_create_user_command('DapUiReset', function()
                ui.toggle({reset = true})
                ui.toggle({reset = true})
            end, {})

            -- Close DAP UI splits when debugging ends (and it doesn't close automatically like it should...)
            vim.api.nvim_create_user_command('DapUiClose', function()
                ui.close()
            end, {})

            local home_path = os.getenv("HOME") .. "/"
            local bin_locations = home_path .. ".local/share/nvim/mason/bin"

            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                host = "127.0.0.1",
                executable = {
                    command = bin_locations .. "/codelldb",
                    args = { "--port", "${port}" },
                },
            }

            dap.adapters.cppdbg = {
                id = 'cppdbg',
                type = 'executable',
                command = bin_locations .. '/OpenDebugAD7',
            }

            dap.configurations.cpp = {
                {
                    name = "Launch C/C++",
                    type = "cppdbg",
                    request = "launch",
                    program = function()
                        return vim.fn.input('Path to C/C++ executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopAtEntry = true,
                    setupCommands = {
                        {
                            text = '-enable-pretty-printing',
                            description = 'enable pretty printing',
                            ignoreFailures = false
                        },
                    },
                    runInTerminal = false,
                    -- Prompt for arguments dynamically
                    args = function()
                        local input = vim.fn.input('Program arguments: ')
                        return vim.split(input, " ")  -- Split the input into a list of arguments
                    end,
                },
            }
            dap.configurations.c = dap.configurations.cpp

            dap.configurations.rust = {
                {
                    name = "Launch Rust",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to Rust executable: ", vim.fn.getcwd() .. "/target/debug", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    runInTerminal = false,
                    initCommands = function()
                        -- Find out where to look for the pretty printer Python module
                        local rustc_sysroot = vim.fn.trim(vim.fn.system('rustc --print sysroot'))

                        local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
                        local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

                        local commands = {}
                        local file = io.open(commands_file, 'r')
                        if file then
                            for line in file:lines() do
                                table.insert(commands, line)
                            end
                            file:close()
                        end
                        table.insert(commands, 1, script_import)

                        return commands
                    end,
                    args = function()
                        local input = vim.fn.input('Program arguments: ')
                        return vim.split(input, " ")  -- Split the input into a list of arguments
                    end,
                }
            }

            dap.configurations.zig = {
                {
                    name = "Launch Zig Program",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input('Path to Zig executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopAtEntry = true,
                    args = function()
                        local input = vim.fn.input('Program arguments: ')
                        return vim.split(input, " ")
                    end,
                }
            }
        end,
    },
    {
        -- LLM prompting.
        'spenserlee/dingllm.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()

            local system_prompt = [[
            You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code or answer questions.
            Key capabilities:
            - Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
            - Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step-by-step.
            - Spot potential bugs and logical errors. Alert the user and suggest fixes.
            - Upon request, add helpful comments explaining complex or unclear code.
            - Suggest relevant documentation and other resources related to the user's code and questions.
            - Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
            - Consider other possibilities to achieve the result, do not be limited by the prompt.
            - Keep concise and use markdown.
            - When asked to create code, only generate the code. No bugs.
            - Think step by step.
            ]]

            -- local replace_prompt = [[
            -- You are an AI programming assistant integrated into a code editor.
            -- Follow the instructions in the code comments.
            -- Generate code only.
            -- Do not output markdown backticks like this ```.
            -- Think step by step.
            -- If you must speak, do so in comments.
            -- Generate valid code only.
            -- ]]

            local replace_prompt = "You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Never include backticks or markdown formatting in your response. Any comment asking for changes should be removed after being satisfied. Other comments should be left alone."

            local dingllm = require('dingllm')

            -- TODO: Setup Grok API
            -- https://x.ai/blog/api

            local release_url = 'https://generativelanguage.googleapis.com/v1/models'
            -- local g_model = 'gemini-1.5-flash'
            -- local g_model = 'gemini-1.5-pro'

            local beta_url = 'https://generativelanguage.googleapis.com/v1beta/models'
            -- local g_model = 'gemini-2.5-flash-preview-09-2025'
            local g_model = 'gemini-2.5-pro'

            local debug_path = '/tmp/dingllm_debug.log'

            local function confirm_action(prompt_message)
                local input_char = vim.fn.input(prompt_message .. " (Press 'Y' to confirm, any other key to cancel): ")
                return input_char == 'Y'
            end

            -- https://ai.google.dev/gemini-api/docs/models/gemini
            local function gemeni_replace()
                if not confirm_action("Proceed with LLM 'replace' operation?") then
                    print("LLM 'replace' cancelled.")
                    return
                end
                dingllm.invoke_llm_and_stream_into_editor({
                    -- url = release_url,
                    url = beta_url,
                    model = g_model,
                    api_key_name = 'GEMINI_API_KEY_159',
                    system_prompt = replace_prompt,
                    replace = true,
                    debug = true,
                    debug_path = debug_path,
                }, dingllm.make_gemini_spec_curl_args, dingllm.handle_gemini_spec_data)
            end

            local function gemeni_help()
                if not confirm_action("Proceed with LLM 'help' operation?") then
                    print("LLM 'help' cancelled.")
                    return
                end
                dingllm.invoke_llm_and_stream_into_editor({
                    -- url = release_url,
                    url = beta_url,
                    model = g_model,
                    api_key_name = 'GEMINI_API_KEY_159',
                    system_prompt = system_prompt,
                    replace = false,
                    debug = false,
                    debug_path = debug_path,
                }, dingllm.make_gemini_spec_curl_args, dingllm.handle_gemini_spec_data)
            end

            vim.keymap.set({ 'n', 'v' }, '<leader>k', gemeni_replace, { desc = 'llm gemeni' })
            vim.keymap.set({ 'n', 'v' }, '<leader>K', gemeni_help, { desc = 'llm gemeni_help' })
        end,
    },
})

---
-- Diagnostic customization
---
vim.g.diagnostics_active = true
function _G.toggle_diagnostics()
    if vim.g.diagnostics_active then
        vim.diagnostic.enable(false)
        vim.g.diagnostics_active = false
    else
        vim.diagnostic.enable()
        vim.g.diagnostics_active = true
    end
end
-- Toggle diagnostics display, it can be very cluttered.
vim.api.nvim_set_keymap('n', '<leader>tt', ':call v:lua.toggle_diagnostics()<CR>', { noremap = true, silent = true })

-- See :help vim.diagnostic.config()
vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = {
        border = "rounded",
    },
    signs = {
        enable = true,
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN]  = "",
            [vim.diagnostic.severity.INFO]  = "",
            [vim.diagnostic.severity.HINT]  = "󰌵",
        },
        texthl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
            [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
        },
    },
})

vim.o.winborder = 'rounded'

---
-- LSP Keybindings
---

local group = vim.api.nvim_create_augroup("user_cmds", {clear = true})

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "LSP actions",
    callback = function()
        local bufmap = function(mode, lhs, rhs)
            local opts = {buffer = true}
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        bufmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>")
        bufmap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>")
        bufmap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>")
        bufmap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>")
        bufmap("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>")
        bufmap("n", "gr", "<cmd>FzfLua lsp_references<cr>")
        bufmap("n", "<F9>", "<cmd>lua vim.lsp.buf.rename()<cr>")
        bufmap({"n", "x"}, "<F12>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>")
        bufmap("n", "gl", "<cmd>lua vim.diagnostic.open_float()<cr>")
        bufmap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>")
        bufmap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>")

        bufmap("n", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
        bufmap("x", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    end
})


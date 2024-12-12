-- Load regular VIM-compatible settings file.
vim.cmd("source ~/.config/nvim/viml/init.vim")

-- Install Lazy plugin manager.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

 -- Make sure to set `mapleader` before Lazy setup so your mappings are correct.
vim.g.mapleader = " "

-- Set up code folding.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldtext = ""
vim.opt.foldnestmax = 4
-- vim.opt.foldlevelstart = 1

-- TODO: use new LSP foldexpr if available? <https://redd.it/1h34lr4>
-- vim.opt.foldexpr = "v:lua.vim.lsp.foldexpr()"

-- Folding keybinds:
-- * zR: open all folds
-- * zM: close all folds
-- * za: toggle fold at cursor
-- * zA: toggle fold and its children at curso
-- * zj: move to next fold
-- * zk: move to prev fold
-- * see also: <https://www.jackfranklin.co.uk/blog/code-folding-in-vim-neovim/>

-- Show highlight for yanked regions
vim.cmd[[
    augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank
        \ { higroup=(vim.fn["hlexists"]("HighlightedyankRegion") > 0 and
        \ "HighlightedyankRegion" or "IncSearch"), timeout=500 }
    augroup END
]]

local function generate_and_execute_sed_command(args)
    -- Get the current visual selection range
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

    -- Check if "buffer" argument is passed
    if args.args == "buffer" then
        vim.cmd("new") -- Open a new split
        vim.cmd("setlocal buftype=nofile") -- Make the buffer a scratch buffer
        vim.cmd("setlocal bufhidden=wipe") -- Wipe the buffer when closed
        vim.cmd("setlocal noswapfile") -- Disable swapfile for this buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
    else
        -- TODO: fix the newlines not working in output pane...
        -- Print the output inline in the command area for easy copy paste
        vim.api.nvim_out_write(output)
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

-- TODO: add this but for visual selection too.
-- Duplicate a line and comment out the first line
vim.keymap.set('n', 'yc', 'yy<cmd>normal gcc<CR>p')

-- Plugins
require("lazy").setup({
    {
        -- Load colorscheme first.
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            -- require("gruvbox").setup({
            --     italic = {
            --         strings = false,
            --         comments = false,
            --         operators = false,
            --         folds = false,
            --     }
            -- })
            vim.cmd("colorscheme gruvbox")
        end
    },
    -- TODO: how to configure multiple colorschemes and switch between them nicely?
    -- {
    --     https://gist.github.com/sainnhe/587a1bba123cb25a3ed83ced613c20c0
    --     "sainnhe/gruvbox-material",
    --     lazy = false,
    --     priority = 1000,
    --     config = function()
    --         vim.cmd([[
    --             set background=dark
    --             let g:gruvbox_material_background = "medium"
    --             let g:gruvbox_material_foreground = "medium"
    --             let g:gruvbox_material_better_performance = 1
    --             colorscheme gruvbox-material
    --         ]])
    --     end
    -- },
    -- {
    --     "sainnhe/everforest",
    --     config = function()
    --         vim.opt.termguicolors = true
    --         vim.g.everforest_background = "hard"
    --         vim.g.everforest_disable_italic_comment = true
    --         vim.cmd.colorscheme("everforest")
    --     end
    -- },
    {
        -- Status bar customization.
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        -- TODO: would be nice if the branch component also picked up on tags
        config = function()
            require("lualine").setup({
                sections = {
                    lualine_c = {
                        {
                            'filename',
                            file_status = true,      -- Displays file status (readonly status, modified status)
                            newfile_status = false,  -- Display new file status (new file means no write after created)
                            path = 1,                -- 0: Just the filename
                            -- 1: Relative path
                            -- 2: Absolute path
                            -- 3: Absolute path, with tilde as the home directory
                            -- 4: Filename and parent dir, with tilde as the home directory

                            shorting_target = 40,    -- Shortens path to leave 40 spaces in the window
                            -- for other components. (terrible name, any suggestions?)
                            symbols = {
                                modified = '[+]',      -- Text to show when the file is modified.
                                readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
                                unnamed = '[No Name]', -- Text to show for unnamed buffers.
                                newfile = '[New]',     -- Text to show for newly created file before first write
                            }
                        }
                    },
                    lualine_x = {
                        "%{ObsessionStatus()}", "encoding", "fileformat", "filetype"
                    },
                },
            })
        end
    },
    {
        -- For unifying TMUX pane / VIM split navigation.
        -- TODO: try replacing with smart-splits.nvim
        "alexghergh/nvim-tmux-navigation",
        lazy = false,
        config = function()
            local nvim_tmux_nav = require("nvim-tmux-navigation")
            nvim_tmux_nav.setup {
                disable_when_zoomed = true,
            }
            vim.keymap.set("n", "<M-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
            vim.keymap.set("n", "<M-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
            vim.keymap.set("n", "<M-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
            vim.keymap.set("n", "<M-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
            vim.keymap.set("n", "<M-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
            vim.keymap.set("n", "<M-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
        end,
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
        },
    },
    {
        -- File explorer as regular buffer.
        "stevearc/oil.nvim",
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
        },
        -- TODO: find out why it breaks netrw / submit issue
        init = function()
            -- disable netrw for now
            vim.g.loaded_netrwPlugin = 1
            vim.g.loaded_netrw = 1
            vim.keymap.set("n", "<leader>o", vim.cmd.Oil, { desc = "Open Oil in a buffer" })
            vim.keymap.set("n", "<leader>O", "<cmd>Oil --float<CR>", { desc = "Open Oil in a floating window" })
        end
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
        config = function()
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
                end
            })
        end
    },
    {
        -- VCS independent gutter display
        -- TODO: the gutter display is kinda borked, skip it for now
        -- "mhinz/vim-signify",
        -- init = function()
        --    -- decrease time to swap file write so git gutter updates sooner
        --     vim.api.nvim_set_option("updatetime", 300)
        -- end,
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
        -- TODO: disable this for DAP panes?
        'b0o/incline.nvim',
        config = function()
            require('incline').setup({
                window = {
                    zindex = 39
                }
            })
        end,
        -- Optional: Lazy load Incline
        event = 'VeryLazy',
    },
    {
        -- Declutter visuals and just focus on one buffer.
        "folke/zen-mode.nvim",
        opts = {
            -- TODO: broken in some edge cases like diffview commit log popup.
            zindex = 42,
            window = {
                width = 0.6
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
                require('incline').disable()
                vim.fn.system([[tmux set status off]])
                vim.fn.system(
                [[tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z]])
            end,
            on_close = function(_)
                require('incline').enable()
                vim.fn.system([[tmux set status on]])
            end
        },
        keys = {
            {"<leader>z", "<cmd>ZenMode<cr>", desc = "ZenMode"},
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
        -- TODO: revisit RRethy/vim-illuminate as an alternative later
        'tzachar/local-highlight.nvim',
        config = function()
            require('local-highlight').setup({
                -- disable_file_types = {'tex'},
                hlgroup = 'Visual',
                cw_hlgroup = nil, -- highlight under cursor
                insert_mode = false,
            })

            vim.api.nvim_set_option("updatetime", 400)
        end
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
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "mfussenegger/nvim-dap",
            "jay-babu/mason-nvim-dap.nvim",
        },
        config = function()
            -- import mason
            local mason = require("mason")

            -- import mason-lspconfig
            local mason_lspconfig = require("mason-lspconfig")
            local mason_tool_installer = require("mason-tool-installer")
            -- local mason_dap = require("mason-nvim-dap")

            -- enable mason and configure icons
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

            mason_lspconfig.setup({
                ensure_installed = {
                    "bashls",
                    "clangd",
                    "dockerls",
                    "lua_ls",
                    "pylsp",
                    -- "rust_analyzer",
                    "yamlls",
                },
                -- auto-install configured servers (with lspconfig)
                automatic_installation = true, -- not the same as ensure_installed
            })

            mason_tool_installer.setup({
                ensure_installed = {
                    -- Formatter and Linters
                    "cmakelang", -- CMake
                    "markdownlint", --Markdown

                    -- Linters
                    -- "pylint", -- Python
                    -- "luacheck", -- Lua

                    -- Debugger adapters
                    "bash-debug-adapter", -- Shell
                    "codelldb", -- C/C++/Rust
                    -- "debugpy", -- Python
                },
            })
        end,
    },
    {
        -- Configures rust-analyzer builtin LSP client + integrates with other Rust tools.
        -- https://github.com/mrcjkb/rustaceanvim/discussions/122
        'mrcjkb/rustaceanvim',
        version = '^5', -- Recommended
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
                            checkOnSave = {
                                -- default: `cargo check`
                                command = "clippy",
                                allFeatures = true,
                                extraArgs = { "--no-deps" },
                            },
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
        -- Some basic default client configuration setings for NVIM LSP.
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "folke/neodev.nvim",  -- LSP for nvim config itself
                config = function()
                    require("neodev").setup()
                end
            },
        },
        -- TODO: keep it simple and put the config here. Probably need to ensure this is
        -- available before mason-lspconfig setup can run...
        -- config = function()
        --     require("lspconfig").setup({
        --         servers = {
        --             rust_analyzer = {},
        --         },
        --     })
        -- end,
    },
    {
        -- Solves the terrible native lsp inlay hint behaviour.
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
        -- useful command to toggle inlay hint native display
        -- require("lsp-endhints").toggle()
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
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "c",
                    "cpp",
                    "lua",
                    "vim",
                    "vimdoc",
                    "query",
                    "rust",
                    "markdown",
                    "markdown_inline",
                    "python",
                    "meson",
                },
                with_sync = true,
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,
                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = false,
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
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
        end,
    },
    {
        -- Visual plugin to better display indentation level and current scope.
        "lukas-reineke/indent-blankline.nvim",
        main= "ibl",
        event = "BufReadPost",
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
    -- Autocompletion.
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp",
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            {
                "L3MON4D3/LuaSnip",
                version = "v2.*",
                -- install jsregexp (optional!).
                build = "make install_jsregexp",
                dependencies = { "rafamadriz/friendly-snippets" },
            },
            'saadparwaiz1/cmp_luasnip',
            "onsails/lspkind.nvim", -- vs-code like pictograms
        },
        config = function()
            local cmp = require("cmp")
            local lspkind = require("lspkind")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()

            local select_opts = {behavior = cmp.SelectBehavior.Select}
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = 'nvim_lsp_signature_help' },
                    { name = "luasnip", keyword_length = 2 },
                    { name = "buffer", keyword_length = 3 },
                    { name = "path" },
                    { name = 'orgmode' },
                }),
                preselect = cmp.PreselectMode.None,
                completion = {
                    completeopt = 'menu,menuone,preview',
                },
                window = {
                    completion = {
                        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
                        col_offset = -3,
                        side_padding = 0,
                        border = 'rounded',
                    },
                    documentation = {
                        border = 'rounded',
                    }
                },
                formatting = {
                    expandable_indicator = false,
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, vim_item)
                        local kind = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
                        local strings = vim.split(kind.kind, "%s", { trimempty = true })
                        kind.kind = " " .. (strings[1] or "") .. " "
                        kind.menu = "    (" .. (strings[2] or "") .. ")"

                        return kind
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Up>"] = cmp.mapping.select_prev_item(select_opts),
                    ["<Down>"] = cmp.mapping.select_next_item(select_opts),
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-y"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.close(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item(select_opts)
                        elseif luasnip.locally_jumpable(1) then
                            luasnip.jump(1)
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item(select_opts)
                        elseif luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
            })

            vim.cmd([[
              set completeopt=menuone,noinsert,noselect
              highlight! default link CmpItemKind CmpItemMenuDefault
            ]])
        end,
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
                        size = 70
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
                    require("neodev").setup({
                      library = { plugins = { "nvim-dap-ui" }, types = true },
                    })
                end,
                dependencies = {
                    "folke/neodev.nvim",
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
                -- Remove surrounding quotes if present
                local condition = args.args:match('^"(.*)"$') or args.args
                dap.toggle_breakpoint(condition)
            end, { nargs = 1 })

            vim.keymap.set("n", "<leader>gb", dap.run_to_cursor)
            vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
            vim.keymap.set("n", "<leader>B", function()
                local condition = vim.fn.input("Enter condition: ")
                vim.cmd("DapConditional " .. vim.fn.shellescape(condition))
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
                    name = "Launch file",
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
                    name = "Launch",
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
                }
            }

        end,
    },

    -- LLM coding
    {
        'spenserlee/dingllm.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()

            local system_prompt = [[
            You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code or answer questions.
            Key capabilities:
            - Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
            - Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step- Spot potential bugs and logical errors. Alert the user and suggest fixes.
            - Upon request, add helpful comments explaining complex or unclear code.
            - Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
            - Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
            - Consider other possibilities to achieve the result, do not be limited by the prompt.
            - Keep concise and use markdown.
            - When asked to create code, only generate the code. No bugs.
            - Think step by step.
            ]]

            local replace_prompt = [[
            You are an AI programming assistant integrated into a code editor.
            Follow the instructions in the code comments.
            Generate code only.
            Do not output markdown backticks like this ```.
            Think step by step.
            If you must speak, do so in comments.
            Generate valid code only.
            ]]

            local dingllm = require('dingllm')

            -- TODO: Setup Grok API
            -- https://x.ai/blog/api

            local release_url = 'https://generativelanguage.googleapis.com/v1/models'
            -- local g_model = 'gemini-1.5-flash'
            -- local g_model = 'gemini-1.5-pro'

            local beta_url = 'https://generativelanguage.googleapis.com/v1beta/models'
            -- local g_model = 'gemini-exp-1206'
            local g_model = 'gemini-2.0-flash-exp'

            local debug_path = '/tmp/dingllm_debug.log'

            -- https://ai.google.dev/gemini-api/docs/models/gemini
            local function gemeni_replace()
                dingllm.invoke_llm_and_stream_into_editor({
                    -- url = release_url,
                    url = beta_url,
                    model = g_model,
                    api_key_name = 'GEMINI_API_KEY_159',
                    system_prompt = replace_prompt,
                    replace = true,
                    debug = false,
                    debug_path = debug_path,
                }, dingllm.make_gemini_spec_curl_args, dingllm.handle_gemini_spec_data)
            end

            local function gemeni_help()
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
vim.api.nvim_set_keymap('n', '<leader>tt', ':call v:lua.toggle_diagnostics()<CR>', { noremap = true, silent = false })

local sign = function(opts)
    -- See :help sign_define()
    vim.fn.sign_define(opts.name, {
        texthl = opts.name,
        text = opts.text,
        numhl = ""
    })
end

sign({name = "DiagnosticSignError", text = ""})
sign({name = "DiagnosticSignWarn", text = ""})
sign({name = "DiagnosticSignHint", text = "󰌵"})
sign({name = "DiagnosticSignInfo", text = ""})

-- See :help vim.diagnostic.config()
vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = {
        border = "rounded",
        -- source = "always",
    },
})

-- there is a bug with documentation hover windows with extra spacing.
-- https://github.com/neovim/neovim/issues/25366
--
-- it seems like the nvim maintainers are just deleting comments about it???
-- https://github.com/neovim/neovim/issues/25718
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
    vim.lsp.handlers.hover,
    {border = "rounded"}
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {border = "rounded"}
)

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

        -- You can search each function in the help page.
        -- For example :help vim.lsp.buf.hover()

        bufmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>")
        bufmap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>")
        bufmap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>")
        bufmap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>")
        bufmap("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>")
        -- bufmap("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>")
        bufmap("n", "gr", "<cmd>FzfLua lsp_references<cr>")
        bufmap("n", "<leader>H", "<cmd>lua vim.lsp.buf.signature_help()<cr>")
        bufmap("n", "<F9>", "<cmd>lua vim.lsp.buf.rename()<cr>")
        bufmap({"n", "x"}, "<F12>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>")
        bufmap("n", "gl", "<cmd>lua vim.diagnostic.open_float()<cr>")
        bufmap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>")
        bufmap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>")

        bufmap("n", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
        bufmap("x", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    end
})

---
-- LSP servers
---
-- See :help mason-lspconfig-dynamic-server-setup

local lspconfig = require("lspconfig")

require("mason-lspconfig").setup_handlers({
    function(server)
        -- See :help lspconfig-setup
        lspconfig[server].setup({})
    end,
    -- don't setup rust_analyzer with meson, rustaceanvim handles it now.
    ["rust_analyzer"] = function () end,
    ["lua_ls"] = function ()
        lspconfig.lua_ls.setup {
            settings = {
                Lua = {
                    library = {
                        checkThirdParty = false,
                    },
                    diagnostics = {
                        globals = { "vim" },
                    },
                    telemetry = {
                        enable = false,
                    },
                },
            },
        }
    end,
    ["pylsp"] = function ()
        -- github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
        lspconfig.pylsp.setup {
            settings = {
                pylsp = {
                    plugins = {
                        pycodestyle = {
                            -- ignore = {'W391'},
                            maxLineLength = 100
                        }
                    }
                }
            }
        }
    end,
})

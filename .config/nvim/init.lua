-- Keep nvim/vim independent configs in vimscript for basic functionality
vim.cmd("source ~/.config/nvim/viml/init.vim")

-- @nocheckin
-- good references
-- https://github.com/Alexis12119/nvim-config/blob/main/lua/core/autocommands.lua
-- https://github.com/rebelot/dotfiles/tree/master

-- Install Lazy plugin manager
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

 -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.mapleader = " "

-- highlight yanked regions
vim.cmd[[
    augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank
        \ { higroup=(vim.fn["hlexists"]("HighlightedyankRegion") > 0 and
        \ "HighlightedyankRegion" or "IncSearch"), timeout=500 }
    augroup END
]]

-- Function to generate and execute a sed command based on visual selection
local function generate_and_execute_sed_command(args)
    -- Get the current visual selection range
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    -- Get the full path to the current buffer file, properly quoted
    local file_path = vim.fn.shellescape(vim.fn.expand("%:p"))
    if file_path == "" then
        print("Buffer does not have a file path.")
        return
    end

    -- Construct the sed command
    local sed_command = string.format("sed -n '%d,%dp' %s", start_line, end_line, file_path)

    -- print("Running command: " .. sed_command)
    print(sed_command)

    -- Execute the command and capture the output
    local output = vim.fn.system(sed_command)
    -- local output = raw_output:gsub("\r\n", "\n"):gsub("\r", "\n")

    -- Check if "buffer" argument is passed
    if args.args == "buffer" then
        -- Print the output in a new buffer
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

-- Create a Neovim command to run the function
vim.api.nvim_create_user_command(
    "SedDump",
    generate_and_execute_sed_command,
    {
        range = true,
        nargs = "?",
        desc = "Generate and execute sed command based on visual selection (optionally output to buffer)"
    }
)


-- Plugins
require("lazy").setup({
    {
        -- colorscheme
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
        -- TMUX pane / VIM split
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
    { "tpope/vim-obsession" },
    {
        "ibhagwan/fzf-lua",
        keys = {
            {"<C-p>", "<cmd>FzfLua git_files<cr>", desc = "FZF git files"},
            {"<leader>ff", "<cmd>FzfLua files<cr>", desc = "FZF files"},
            {"<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "FZF recent files"},
            {"<leader>/", "<cmd>FzfLua grep_cword<cr>", desc = "FZF word under cursor"},
            {"<leader>L", "<cmd>FzfLua resume<cr>", desc = "FZF resume last search"},
            {"<leader>?", "<cmd>FzfLua grep<cr>", desc = "FZF search"},
            {"<leader><space>", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
            -- {"<leader>b", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
            {"<leader>l", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
            {"<leader>c", "<cmd>FzfLua commands<cr>", desc = "FZF commands"},
            {"<leader>s", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "LSP Document Symbols"},
        },
    },
    {
        -- File explorer as regular buffer
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
    {
        -- Git tools
        -- TODO: find a solution so git plugins can be utilized with bare repo
        -- workaround by invoking nvim with explicit env var:
        --   GIT_DIR=$HOME/.dotfiles GIT_WORK_TREE=$HOME nvim .config/nvim/init.lua
        "tpope/vim-fugitive",
    },
    {
        "sindrets/diffview.nvim",
    },
    {
        -- Git gutter display
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
        -- Multiple search highlights is so great for log analysis
        "azabiong/vim-highlighter",
        lazy = false,
        keys = {
            -- highlights across window splits :Hi ==
            -- hightlights only in current window  :Hi =
            {"<leader>n", "<cmd>Hi}<cr>", desc = "Highlighter next recent"},
            {"<leader>N", "<cmd>Hi{<cr>", desc = "Highlighter prev recent"},
            {"<leader>}", "<cmd>Hi><cr>", desc = "Highlighter next any"},
            {"<leader>{", "<cmd>Hi<<cr>", desc = "Highlighter prev any"},
        },
        config = function()
            -- set global highlights by default
            vim.cmd("Hi ==")
        end
    },
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
            local opts = { remap = true, silent = true }
            -- CTRL + / to toggle comments in normal/visual mode
            vim.keymap.set("n", "<C-_>", "gcc", opts)
            vim.keymap.set("v", "<C-_>", "gc", opts)
        end
    },
    {
        -- displays filename on each split in floating in top right
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
        "folke/zen-mode.nvim",
        opts = {
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
                -- vim.fn.system(
                -- [[tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z]])
            end
        },
        keys = {
            {"<leader>z", "<cmd>ZenMode<cr>", desc = "ZenMode"},
            -- {"<leader>z", "<cmd>lua require('incline').toggle()<cr><cmd>ZenMode<cr>", desc = "ZenMode"},
        }
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup()
        end
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
    {
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
        -- Navigate by eye
        "ggandor/leap.nvim",
        config = function()
            require("leap").add_default_mappings()

            -- don't overwrite the default delete keymapping, I only use sS
            vim.keymap.del({'x', 'o'}, 'x')
            vim.keymap.del({'x', 'o'}, 'X')
        end
    },
    {
        -- highlight word under cursor
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
    -- TODO: this one messes with keymaps somehow... and annoyingly highlight
    -- within blocks
    -- {
    --     "RRethy/vim-illuminate",
    --     config = function()
    --         require("illuminate").configure{}
    --         -- change the highlight style
    --         vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
    --         vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
    --         vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
    --
    --         vim.cmd [[
    --             hi def IlluminatedWordText guifg=none guibg=none gui=underline
    --             hi def IlluminatedWordRead guifg=none guibg=none gui=underline
    --             hi def IlluminatedWordWrite guifg=none guibg=none gui=underline
    --             ]]
    --
    --         --- auto update the highlight style on colorscheme change
    --         -- vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    --         --     pattern = { "*" },
    --         --     callback = function(ev)
    --         --         vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
    --         --         vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
    --         --         vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
    --         --     end
    --         -- })
    --     end
    -- }, 
    {
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
                    -- "eslint_d", -- Javascript and more
                    -- "cmakelint", -- CMake
                    -- "luacheck", -- Lua
                    -- "jsonlint", -- Json
                    -- "golangci-lint", -- Golang
                    -- "checkstyle", -- Overall
                    -- "yamllint", -- Yaml
                    -- "stylelint", -- CSS/SCSS etc

                    -- Formatters
                    -- "stylua", -- lua
                    -- "prettier",
                    -- "isort", -- python
                    -- "black", -- python
                    -- "htmlbeautifier", -- HTML
                    -- "beautysh", --Shell
                    -- "latexindent", --Latex
                    -- "csharpier", --C#
                    -- "clang-format", --C/C++
                    -- "pretty-php", --PHP

                    -- Debugger adapters
                    "bash-debug-adapter", -- Shell
                    "codelldb", -- C/C++/Rust
                    -- "debugpy", -- Python
                    -- "java-debug-adapter", -- Java
                    -- "js-debug-adapter", -- Javascript
                    -- "kotlin-debug-adapter", -- Kotlin
                    -- "netcoredbg", -- C#
                    -- "php-debug-adapter", -- PHP
                },
            })

            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
        end,
    },
    {
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
                -- DAP configuration
                dap = {},
            }
         end
     },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "folke/neodev.nvim",  -- LSP for nvim config itself
                config = function()
                    require("neodev").setup()
                end
            },
        },
        -- config = function()
        --     require("lspconfig").setup({
        --         servers = {
        --             rust_analyzer = {},
        --         },
        --     })
        -- end,
    },
    {
        -- nice plugin which solves the terrible native lsp inlay hint behaviour.
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
    -- {
    --     "lukas-reineke/indent-blankline.nvim",
    --     event = "BufReadPost",
    --     config = function()
    --         require("indent_blankline").setup {
    --             buftype_exclude = {"terminal", "prompt", "nofile"},
    --             filetype_exclude = {
    --                 'help', 'dashboard', 'Trouble', 'dap.*', 'NvimTree',
    --                 "packer"
    --             },
    --             show_current_context = true,
    --             show_current_context_start = false,
    --             show_trailing_blankline_indent = false,
    --             -- use_treesitter = true,
    --             -- use_treesitter_scope = true
    --             -- context_patterns = {
    --             --     'class', 'func', 'method', '.*_statement', 'table'
    --             -- }
    --         }
    --     end,
    -- },

    -- Autocomplete
    {"hrsh7th/nvim-cmp"},
    {"hrsh7th/cmp-buffer"},
    {"hrsh7th/cmp-path"},
    {"hrsh7th/cmp-nvim-lsp"},
    {"saadparwaiz1/cmp_luasnip"},

    -- Snippets
    {"L3MON4D3/LuaSnip"},
    {"rafamadriz/friendly-snippets"},

    -- Debugging
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
            "williamboman/mason.nvim",
        },
        config = function()
            local dap = require "dap"
            local ui = require "dapui"

            -- command to reset DAP UI panes
            -- :lua require('dapui').toggle({reset=true})
            require("dapui").setup({
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
            })
            require("nvim-dap-virtual-text").setup({})

            vim.keymap.set("n", "<space>b", dap.toggle_breakpoint)
            vim.keymap.set("n", "<space>gb", dap.run_to_cursor)

            -- Eval var under cursor
            vim.keymap.set("n", "<space>;", function()
                require("dapui").eval(nil, { enter = true })
            end)

            vim.keymap.set("n", "<F1>", dap.continue)
            vim.keymap.set("n", "<F2>", dap.step_into)
            vim.keymap.set("n", "<F3>", dap.step_over)
            vim.keymap.set("n", "<F4>", dap.step_out)
            vim.keymap.set("n", "<F5>", dap.step_back) -- only for rr?

            vim.keymap.set('n', '<F6>', dap.up)
            vim.keymap.set('n', '<F7>', dap.down)

            vim.keymap.set("n", "<F10>", dap.restart)

            -- NOTE: you can execute GDB commands in the DAP-REPL window with `-exec` prefix
            -- -exec p/x cur
            -- $2 = 0x7fffd96ef052

            dap.listeners.before.attach.dapui_config = function() ui.open() end
            dap.listeners.before.launch.dapui_config = function() ui.open() end
            dap.listeners.before.event_terminated.dapui_config = function() ui.close() end
            dap.listeners.before.event_exited.dapui_config = function() ui.close() end

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
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
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
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug", "file")
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

            -- local system_prompt = [[
            -- You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code.
            -- Key capabilities:
            -- - Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
            -- - Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step- Spot potential bugs and logical errors. Alert the user and suggest fixes.
            -- - Upon request, add helpful comments explaining complex or unclear code.
            -- - Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
            -- - Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
            -- - Keep concise and use markdown.
            -- - When asked to create code, only generate the code. No bugs.
            -- - Think step by step
            -- ]]

            -- local system_prompt_replace = "Follow the instructions in the code comments. Generate code only. Think step by step. If you must speak, do so in comments. Generate valid code only."
            --
            local system_prompt = [[
            You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code.  Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone.
            Instructions for the output format:
            - Output code without descriptions, unless it is important.
            - Minimize prose, comments and empty lines.
            - Do not provide any backticks that surround the code.
            - Never ever output backticks like this ```.
            - Make it easy to copy and paste.
            - Consider other possibilities to achieve the result, do not be limited by the prompt.
            ]]

            -- local system_prompt =
            -- 'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
            local helpful_prompt = 'You are a helpful assistant. What I have sent are my notes so far.'
            local dingllm = require 'dingllm'


            -- https://ai.google.dev/gemini-api/docs/models/gemini
            local function gemeni_replace()
                dingllm.invoke_llm_and_stream_into_editor({
                    url = 'https://generativelanguage.googleapis.com/v1/models',
                    model = 'gemini-1.5-flash',
                    api_key_name = 'GEMINI_API_KEY_159',
                    system_prompt = system_prompt,
                    replace = true,
                }, dingllm.make_gemini_spec_curl_args, dingllm.handle_gemini_spec_data)
            end

            local function gemeni_help()
                dingllm.invoke_llm_and_stream_into_editor({
                    url = 'https://generativelanguage.googleapis.com/v1/models',
                    model = 'gemini-1.5-flash',
                    api_key_name = 'GEMINI_API_KEY_159',
                    system_prompt = helpful_prompt,
                    replace = false,
                }, dingllm.make_gemini_spec_curl_args, dingllm.handle_gemini_spec_data)
            end

            -- https://console.groq.com/docs/models
            local function groq_replace()
                dingllm.invoke_llm_and_stream_into_editor({
                    url = 'https://api.groq.com/openai/v1/chat/completions',
                    -- model = 'llama-3.1-70b-versatile',
                    -- model = 'llama-3.1-8b-instant'
                    model = 'llama3-70b-8192',
                    api_key_name = 'GROQ_API_KEY',
                    system_prompt = system_prompt,
                    replace = true,
                }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
                -- }, dingllm.make_openai_spec_curl_args, dingllm.handle_groq_spec_data)
            end

            local function groq_help()
                dingllm.invoke_llm_and_stream_into_editor({
                    url = 'https://api.groq.com/openai/v1/chat/completions',
                    -- model = 'llama-3.1-70b-versatile',
                    -- model = 'llama-3.1-8b-instant'
                    model = 'llama3-70b-8192',
                    api_key_name = 'GROQ_API_KEY',
                    system_prompt = helpful_prompt,
                    replace = false,
                }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
                -- }, dingllm.make_openai_spec_curl_args, dingllm.handle_groq_spec_data)
            end

            -- vim.keymap.set({ 'n', 'v' }, '<leader>g', groq_replace, { desc = 'llm groq' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>G', groq_help, { desc = 'llm groq_help' })
            vim.keymap.set({ 'n', 'v' }, '<leader>k', gemeni_replace, { desc = 'llm gemeni' })
            vim.keymap.set({ 'n', 'v' }, '<leader>K', gemeni_help, { desc = 'llm gemeni_help' })
        end,
    },
})

---
-- Luasnip (snippet engine)
---
-- See :help luasnip-loaders
require("luasnip.loaders.from_vscode").lazy_load()

---
-- nvim-cmp (autocomplete)
---
vim.opt.completeopt = {"menu", "menuone", "noselect"}

local cmp = require("cmp")
local luasnip = require("luasnip")

local select_opts = {behavior = cmp.SelectBehavior.Select}

local has_words_before = function()
    unpack = unpack or table.unpack
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end


-- TODO: add completions from other visible buffers
-- https://github.com/hrsh7th/cmp-buffer#visible-buffers
-- See :help cmp-config
cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    sources = {
        {name = "path"},
        {name = "nvim_lsp"},
        {name = "buffer", keyword_length = 3},
        {name = "luasnip", keyword_length = 2},
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    formatting = {
        fields = {"menu", "abbr", "kind"},
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = "λ",
                luasnip = "⋗",
                buffer = "",
                path = "󰆓",
            }

            item.menu = menu_icon[entry.source.name]
            return item
        end,
    },
    -- See :help cmp-mapping
    mapping = {
        ["<Up>"] = cmp.mapping.select_prev_item(select_opts),
        ["<Down>"] = cmp.mapping.select_next_item(select_opts),

        ["<C-p>"] = cmp.mapping.select_prev_item(select_opts),
        ["<C-n>"] = cmp.mapping.select_next_item(select_opts),

        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),

        ["<C-e>"] = cmp.mapping.abort(),
        ["<C-y>"] = cmp.mapping.confirm({select = true}),
        ["<CR>"] = cmp.mapping.confirm({select = false}),

        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
                -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
                -- they way you will only jump inside the snippet region
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    },
})


---
-- Mason.nvim
---
-- See :help mason-settings
-- require("mason").setup({
--     ui = {border = "rounded"}
-- })

-- See :help mason-lspconfig-settings
-- require("mason-lspconfig").setup({
--     ensure_installed = {
--         "bashls",
--         "clangd",
--         "dockerls",
--         "lua_ls",
--         "pylsp",
--         "rust_analyzer",
--         "yamlls",
--     },
--     -- auto-install configured servers (with lspconfig)
--     automatic_installation = true, -- not the same as ensure_installed
-- })
--
---
-- LSP config
---
-- See :help lspconfig-global-defaults
local lspconfig = require("lspconfig")
local lsp_defaults = lspconfig.util.default_config

lsp_defaults.capabilities = vim.tbl_deep_extend(
    "force",
    lsp_defaults.capabilities,
    require("cmp_nvim_lsp").default_capabilities()
)

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
        bufmap("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>")
        bufmap("n", "<F11>", "<cmd>lua vim.lsp.buf.rename()<cr>")
        bufmap({"n", "x"}, "<F12>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>")
        bufmap("n", "gl", "<cmd>lua vim.diagnostic.open_float()<cr>")
        bufmap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>")
        bufmap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>")

        bufmap("n", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
        bufmap("x", "<F8>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    end
})


-- lspconfig.rust_analyzer.setup({
--     filetypes = {"rust"},
--     on_attach = function(client, bufnr)
--         vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
--     end,
--     settings = {
--         ['rust_analyzer'] = {
--             cargo = {
--                 allFeatures = true
--             },
--             -- checkOnSave = {
--             --   command = "clippy"
--             -- },
--         },
--     },
-- })


---
-- LSP servers
---
-- See :help mason-lspconfig-dynamic-server-setup
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
})

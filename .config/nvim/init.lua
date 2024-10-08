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
            {"<leader>l", "<cmd>FzfLua resume<cr>", desc = "FZF resume last search"},
            {"<leader>?", "<cmd>FzfLua grep<cr>", desc = "FZF search"},
            {"<leader><space>", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
            {"<leader>b", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
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
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "folke/neodev.nvim",  -- LSP for nvim config itself
                config = function()
                    require("neodev").setup()
                end
            },
        }
    },
    -- TODO: get nvim-dap working with rust.. it's a huge pain..
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
    },
    {"williamboman/mason-lspconfig.nvim"},
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            -- vim.g.rustfmt_autosave = 1
        end
    },
    {"simrat39/rust-tools.nvim"},

    -- rustaceanvim supposedly replaces rust-tools and claims "no setup", but I
    -- cannot get it to work...
    -- {
    --     'mrcjkb/rustaceanvim',
    --     version = '^4', -- Recommended
    --     ft = { 'rust' },
    --     lazy = false,
    --     init = function()
    --         vim.g.rustaceanvim = {
    --             -- Plugin configuration
    --             tools = {
    --                 autoSetHints = true,
    --                 inlay_hints = {
    --                     show_parameter_hints = true,
    --                     parameter_hints_prefix = "<- ",
    --                     other_hints_prefix = "=> "
    --                 }
    --             },
    --             -- LSP configuration
    --             server = {
    --                 on_attach = function(client, bufnr)
    --                     mappings(client, bufnr)
    --                     require("illuminate").on_attach(client)
    --
    --                     local bufopts = {
    --                         noremap = true,
    --                         silent = true,
    --                         buffer = bufnr
    --                     }
    --                     -- vim.keymap.set('n', '<leader><leader>rr', "<Cmd>RustLsp runnables<CR>", bufopts)
    --                     vim.keymap.set('n', 'K', "<Cmd>RustLsp hover actions<CR>", bufopts)
    --                 end,
    --                 settings = {
    --                     -- rust-analyzer language server configuration
    --                     ['rust-analyzer'] = {
    --                         assist = {
    --                             importEnforceGranularity = true,
    --                             importPrefix = "create"
    --                         },
    --                         cargo = { allFeatures = true },
    --                         checkOnSave = {
    --                             -- default: `cargo check`
    --                             command = "clippy",
    --                             allFeatures = true
    --                         },
    --                         inlayHints = {
    --                             lifetimeElisionHints = {
    --                                 enable = true,
    --                                 useParameterNames = true
    --                             }
    --                         }
    --                     }
    --                 }
    --             },
    --             -- DAP configuration
    --             dap = {
    --             },
    --         }
    --     end
    -- },

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
    -- {"mfussenegger/nvim-dap"},


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
            -- vim.keymap.set({ 'n', 'v' }, '<leader>o', llama_405b_base, { desc = 'llama base' })

            -- local function handle_open_router_spec_data(data_stream)
            --     local success, json = pcall(vim.json.decode, data_stream)
            --     if success then
            --         if json.choices and json.choices[1] and json.choices[1].text then
            --             local content = json.choices[1].text
            --             if content then
            --                 dingllm.write_string_at_cursor(content)
            --             end
            --         end
            --     else
            --         print("non json " .. data_stream)
            --     end
            -- end
            --
            -- local function custom_make_openai_spec_curl_args(opts, prompt)
            --     local url = opts.url
            --     local api_key = opts.api_key_name and os.getenv(opts.api_key_name)
            --     local data = {
            --         prompt = prompt,
            --         model = opts.model,
            --         temperature = 0.7,
            --         stream = true,
            --     }
            --     local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
            --     if api_key then
            --         table.insert(args, '-H')
            --         table.insert(args, 'Authorization: Bearer ' .. api_key)
            --     end
            --     table.insert(args, url)
            --     return args
            -- end
            --
            -- local function llama_405b_base()
            --     dingllm.invoke_llm_and_stream_into_editor({
            --         url = 'https://openrouter.ai/api/v1/chat/completions',
            --         model = 'meta-llama/llama-3.1-405b',
            --         api_key_name = 'OPEN_ROUTER_API_KEY',
            --         max_tokens = '128',
            --         replace = false,
            --     }, custom_make_openai_spec_curl_args, handle_open_router_spec_data)
            -- end
            --
            -- local function llama405b_replace()
            --     dingllm.invoke_llm_and_stream_into_editor({
            --         url = 'https://api.lambdalabs.com/v1/chat/completions',
            --         model = 'hermes-3-llama-3.1-405b-fp8',
            --         api_key_name = 'LAMBDA_API_KEY',
            --         system_prompt = system_prompt,
            --         replace = true,
            --     }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
            -- end
            --
            -- local function llama405b_help()
            --     dingllm.invoke_llm_and_stream_into_editor({
            --         url = 'https://api.lambdalabs.com/v1/chat/completions',
            --         model = 'hermes-3-llama-3.1-405b-fp8',
            --         api_key_name = 'LAMBDA_API_KEY',
            --         system_prompt = helpful_prompt,
            --         replace = false,
            --     }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
            -- end
            --
            -- local function anthropic_help()
            --     dingllm.invoke_llm_and_stream_into_editor({
            --         url = 'https://api.anthropic.com/v1/messages',
            --         model = 'claude-3-5-sonnet-20240620',
            --         api_key_name = 'ANTHROPIC_API_KEY',
            --         system_prompt = helpful_prompt,
            --         replace = false,
            --     }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
            -- end
            --
            -- local function anthropic_replace()
            --     dingllm.invoke_llm_and_stream_into_editor({
            --         url = 'https://api.anthropic.com/v1/messages',
            --         model = 'claude-3-5-sonnet-20240620',
            --         api_key_name = 'ANTHROPIC_API_KEY',
            --         system_prompt = system_prompt,
            --         replace = true,
            --     }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
            -- end

            -- vim.keymap.set({ 'n', 'v' }, '<leader>k', groq_replace, { desc = 'llm groq' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>K', groq_help, { desc = 'llm groq_help' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>L', llama405b_help, { desc = 'llm llama405b_help' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>l', llama405b_replace, { desc = 'llm llama405b_replace' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>I', anthropic_help, { desc = 'llm anthropic_help' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>i', anthropic_replace, { desc = 'llm anthropic' })
            -- vim.keymap.set({ 'n', 'v' }, '<leader>o', llama_405b_base, { desc = 'llama base' })
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
require("mason").setup({
    ui = {border = "rounded"}
})

-- See :help mason-lspconfig-settings
require("mason-lspconfig").setup({
    ensure_installed = {
        "bashls",
        "clangd",
        -- "codelldb",
        "dockerls",
        "lua_ls",
        "pylsp",
        "rust_analyzer",
        "yamlls",
        -- "taplo",
    }
})

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
        vim.diagnostic.disable()
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
        source = "always",
    },
})

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
        bufmap("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>")
        bufmap({"n", "x"}, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>")
        bufmap("n", "gl", "<cmd>lua vim.diagnostic.open_float()<cr>")
        bufmap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>")
        bufmap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>")

        bufmap("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
        bufmap("x", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    end
})


---
-- LSP servers
---
-- See :help mason-lspconfig-dynamic-server-setup
require("mason-lspconfig").setup_handlers({
    function(server)
        -- See :help lspconfig-setup
        lspconfig[server].setup({})
    end,
    ["rust_analyzer"] = function ()
        require("rust-tools").setup({
            tools = {
                hover_actions = {
                    auto_focus = true,
                },
            },
        })
    end,
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

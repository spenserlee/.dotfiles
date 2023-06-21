vim.cmd("source ~/.config/nvim/viml/init.vim")

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
            vim.cmd([[colorscheme gruvbox]])
        end
    },
    {
        -- TMUX pane / VIM split
        "alexghergh/nvim-tmux-navigation",
        lazy = false,
        config = function()
            local nvim_tmux_nav = require("nvim-tmux-navigation")
            vim.keymap.set("n", "<M-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
            vim.keymap.set("n", "<M-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
            vim.keymap.set("n", "<M-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
            vim.keymap.set("n", "<M-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
            vim.keymap.set("n", "<M-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
            vim.keymap.set("n", "<M-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
        end,
    },
    {
        -- Find stuff
        "nvim-telescope/telescope.nvim",
        tag = "0.1.1",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
        config = function()
            local ts_actions = require("telescope.actions")
            local ts_config  = require("telescope.config")
            local vimgrep_args = { unpack(ts_config.values.vimgrep_arguments) }

            table.insert(vimgrep_args, "--hidden")
            table.insert(vimgrep_args, "--glob")
            table.insert(vimgrep_args, "!**/.git/*")

            -- TODO: screw telescope searching... just use fzf.vim for this
            require("telescope").setup{
                defaults = {
                    mappings = {
                        i = {
                            ["<esc>"] = ts_actions.close
                        },
                    },
                    vimgrep_arguments = vimgrep_args,
                    fileignore_patterns = { '.git/', 'node_modules/', '.npm/',
                        '[Cc]ache/', '-cache', '.dropbox/', '.dropbox_trashed/',
                        '.py[co]', '.sw?', '~', '.sql', '.tags', '.gemtags',
                        '.csv', '.tsv', '.tmp', '.old', '.plist', '.pdf', '.log',
                        '.jpg', '.jpeg', '.png', '.tar.gz', '.tar', '.zip',
                        '.class', '.pdb', '.dll', '.dat', '.mca', 'pycache_',
                        '.mozilla/', '.electron/', '.vpython-root/', '.gradle/',
                        '.nuget/', '.cargo/', '.evernote/', '.azure-functions-core-tools/',
                        'yay/', '.local/share/Trash/', '.local/share/nvim/swap/', 'code%-other/'
                    }
                },
                pickers = {
                    find_files = {
                        -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                        -- the default case_mode is "smart_case"
                    }
                }
            }
            require('telescope').load_extension('fzf')

            -- TODO: is it better to use "keys" attribute and just set lazy = false?
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "FZF Files" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "FZF recent file" })
            vim.keymap.set("n", "gb", builtin.buffers, { desc = "FZF buffers" })
            vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "FZF git file" })
            vim.keymap.set("n", "<leader>fl", builtin.current_buffer_fuzzy_find, { desc = "FZF current buffer lines" })
            vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "FZF live grep" })
            vim.keymap.set("n", "<leader><S-_>", builtin.grep_string, { desc = "FZF grep string" })
        end
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
        "tpope/vim-fugitive",
    },
    {
        -- Git gutter display
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
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
        -- Multiple search highlights is so great
        -- TODO: redo keybinds
        "azabiong/vim-highlighter",
    },
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
            local opts = { remap = true, silent = true }
            vim.keymap.set("n", "<C-_>", "gcc", opts)
            vim.keymap.set("v", "<C-_>", "gc", opts)
        end
    },
})


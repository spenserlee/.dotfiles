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
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        -- TODO: would be nice if the branch component also picked up on tags
        config = function()
            require("lualine").setup()
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
        "ibhagwan/fzf-lua",
        keys = {
            {"<C-p>", "<cmd>FzfLua git_files<cr>", desc = "FZF git files"},
            {"<leader>ff", "<cmd>FzfLua files<cr>", desc = "FZF files"},
            {"<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "FZF recent files"},
            {"<leader>/", "<cmd>FzfLua grep<cr>", desc = "FZF grep"},
            {"<leader>lg", "<cmd>FzfLua live_grep<cr>", desc = "FZF live grep"},
            {"<leader>b", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
            {"<leader>L", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
            {"<leader>c", "<cmd>FzfLua commands<cr>", desc = "FZF buffers"},
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
    {
        "folke/zen-mode.nvim",
        opts = {
            window = {
                width = 0.6
            }
        },
        keys = {
            {"<leader>z", "<cmd>ZenMode<cr>", desc = "ZenMode"},
        }
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
    {
        -- Navigate by eye
        "ggandor/leap.nvim",
        config = function()
            require("leap").add_default_mappings()
        end
    }
})


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
            vim.keymap.set('n', "<M-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
            vim.keymap.set('n', "<M-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
            vim.keymap.set('n', "<M-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
            vim.keymap.set('n', "<M-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
            vim.keymap.set('n', "<M-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
            vim.keymap.set('n', "<M-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
        end,
    },
    {
        -- TODO: replace with Telescope
        -- Find stuff
        "ibhagwan/fzf-lua",
        keys = {
            {"<C-p>", "<cmd>FzfLua files<cr>", desc = "FZF files"},
            {"<leader>/", "<cmd>FzfLua grep<cr>", desc = "FZF grep"},
            {"<leader>o", "<cmd>FzfLua oldfiles<cr>", desc = "FZF grep"},
            {"gb", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
        },
    },
    {
        "stevearc/oil.nvim",
    },
})

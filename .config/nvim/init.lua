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
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "FZF Files" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "FZF recent file" })
            vim.keymap.set("n", "gb", builtin.buffers, { desc = "FZF buffers" })
            vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "FZF git file" })
            vim.keymap.set("n", "<leader>lg", builtin.live_grep, { desc = "FZF live grep" })
            vim.keymap.set("n", "<leader>/", builtin.grep_string, { desc = "FZF grep" })
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
    -- TODO: replace this with vim-highlighter?
    -- https://github.com/azabiong/vim-highlighter

--    {
--        -- Multiple search highlights
--        "inkarkat/vim-mark",
--        init = function()
--            -- This plugin is great, but the default mappings are...not.
--            -- Disable them all and only setup the ones that are useful to me.
--            vim.g.mw_no_mappings = 1
--            vim.keymap.set("n", "<leader>m", "<cmd><Plug>MarkSet<CR>", { desc = "MarkSet" })
--            vim.keymap.set("n", "<leader>h", "<cmd>:noh<bar>:MarkClear<CR>", { desc = "MarkClear" })
--            vim.keymap.set("n", "<leader>h", "<cmd><Plug>IgnoreMarkSearchNext <Plug>MarkSearchNext<CR>", { desc = "MarkClear" })
--            vim.keymap.set("n", "<leader>h", "<cmd><Plug>IgnoreMarkSearchPrev <Plug>MarkSearchPrev<CR>", { desc = "MarkClear" })
--            vim.keymap.set("n", "<leader>h", "<cmd><Plug>MarkSearchAnyNext<CR>", { desc = "MarkClear" })
--            vim.keymap.set("n", "<leader>h", "<cmd><Plug>MarkSearchAnyPrev<CR>", { desc = "MarkClear" })
--
--            nmap <silent> <F2> <Plug>(lcn-rename)
--            vim.api.nvim_set_keymap('n', '<F2>', "<Plug>(lcn-rename')", { noremap = true, silent = true });
--
--            vim.cmd[[
--                let g:mw_no_mappings = 1
--                nmap <Space>m <Plug>MarkSet
--                map <silent> <Leader>h :noh<bar>:MarkClear<CR>
--                nmap <Plug>IgnoreMarkSearchNext <Plug>MarkSearchNext
--                nmap <Plug>IgnoreMarkSearchPrev <Plug>MarkSearchPrev
--                nmap <Leader>n <Plug>MarkSearchAnyNext
--                nmap <Leader>N <Plug>MarkSearchAnyPrev
--            ]]
--        end
--    },
})


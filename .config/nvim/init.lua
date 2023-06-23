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
            require("gruvbox").setup({
                italic = {
                    strings = false,
                    comments = true,
                    operators = true,
                    folds = true,
                }
            })
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
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        -- TODO: would be nice if the branch component also picked up on tags
        config = function()
            require("lualine").setup({})
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
            {"<leader>?", "<cmd>FzfLua live_grep<cr>", desc = "FZF live grep"},
            {"<leader><space>", "<cmd>FzfLua buffers<cr>", desc = "FZF buffers"},
            {"<leader>l", "<cmd>FzfLua blines<cr>", desc = "FZF buffer lines"},
            {"<leader>c", "<cmd>FzfLua commands<cr>", desc = "FZF buffers"},
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
            -- CTRL + / to toggle comments in normal/visual mode
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
            require("nvim-surround").setup()
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
        }
    },
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
    {"simrat39/rust-tools.nvim"},

    -- Autocomplete
    {"hrsh7th/nvim-cmp"},
    {"hrsh7th/cmp-buffer"},
    {"hrsh7th/cmp-path"},
    {"hrsh7th/cmp-nvim-lsp"},
    {"saadparwaiz1/cmp_luasnip"},

    -- Snippets
    {"L3MON4D3/LuaSnip"},
    {"rafamadriz/friendly-snippets"},
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
        "dockerls",
        "lua_ls",
        "pylsp",
        "rust_analyzer",
        "yamlls",
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
        require("rust-tools").setup({})
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

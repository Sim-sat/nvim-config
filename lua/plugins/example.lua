return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier", "eslint_d" },
        typescript = { "prettier", "eslint_d" },
        javascriptreact = { "prettier", "eslint_d" },
        typescriptreact = { "prettier", "eslint_d" },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  { "nvim-mini/mini.ai" },
  {
    "nvim-mini/mini.files",
    opts = {
      mappings = {
        go_in_plus = "<CR>",
        close = "<Esc>",
      },
    },
    config = function(_, opts)
      require("mini.files").setup(opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id

          vim.keymap.set("n", "<Left>", require("mini.files").go_out, { buffer = buf_id, desc = "Go out" })
          vim.keymap.set("n", "<Right>", require("mini.files").go_in, { buffer = buf_id, desc = "Go in" })
          vim.keymap.set("n", "q", require("mini.files").close, { buffer = buf_id, desc = "Close" })

          vim.keymap.set("n", "gc", function()
            local entry = require("mini.files").get_fs_entry()
            if not entry then
              return
            end
            local dir = entry.fs_type == "directory" and entry.path or vim.fn.fnamemodify(entry.path, ":h")
            vim.cmd.cd(dir)
            vim.notify("cwd: " .. dir)
            require("mini.files").open(dir, false)
          end, { buffer = buf_id, desc = "Set cwd and open" })
        end,
      })
    end,
    keys = {
      {
        "<leader>e",
        function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Open mini.files (current buffer)",
      },
    },
  },

  { "xiyaowong/transparent.nvim" },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      return {
        theme = "doom",
        config = {
          vertical_center = true,
          header = {
            "",
            "",
            "",
            "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
            "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
            "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
            "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
            "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
            "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
            "",
          },
          center = {
            {
              icon = "󰈔 ",
              icon_hl = "DiagnosticInfo",
              desc = "Find Files",
              desc_hl = "String",
              key = "f",
              action = function()
                require("fzf-lua").files()
              end,
            },
            {
              icon = "󰁯 ",
              icon_hl = "DiagnosticWarn",
              desc = "Recent Files",
              desc_hl = "String",
              key = "r",
              action = function()
                require("fzf-lua").oldfiles()
              end,
            },
            {
              icon = "󱉭 ",
              icon_hl = "DiagnosticHint",
              desc = "Recent Projects",
              desc_hl = "String",
              key = "p",
              action = function()
                require("snacks").picker.projects()
              end,
            },
            {
              icon = "󰍉 ",
              icon_hl = "DiagnosticHint",
              desc = "Grep",
              desc_hl = "String",
              key = "g",
              action = function()
                require("snacks").picker.grep()
              end,
            },
            {
              icon = "󰒓 ",
              icon_hl = "DiagnosticWarn",
              desc = "Config",
              desc_hl = "String",
              key = "c",
              action = function()
                require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
              end,
            },
            {
              icon = "󰒲 ",
              icon_hl = "DiagnosticInfo",
              desc = "Lazy",
              desc_hl = "String",
              key = "l",
              action = "Lazy",
            },
            {
              icon = "󰙳 ",
              icon_hl = "DiagnosticHint",
              desc = "Extras",
              desc_hl = "String",
              key = "x",
              action = "LazyExtras",
            },
            {
              icon = "󰩈 ",
              icon_hl = "DiagnosticError",
              desc = "Quit",
              desc_hl = "String",
              key = "q",
              action = "qa",
            },
          },
          footer = function()
            local stats = require("lazy").stats()
            return { "", "⚡ " .. stats.count .. " plugins loaded in " .. stats.startuptime .. "ms" }
          end,
        },
      }
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      explorer = { enabled = false },
      dashboard = { enabled = false },
    },
    keys = {
      { "<leader>e", false }, -- removes LazyVim's default binding
    },
  },
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    branch = "main",
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = { left = "⏐", right = "⏐" },
        section_separators = { left = " ", right = " " }, -- Flacher VS Code Look
        globalstatus = true, -- Eine durchgehende Leiste ganz unten
      },
    },
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
  },
}

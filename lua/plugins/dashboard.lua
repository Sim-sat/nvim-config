return {
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
}

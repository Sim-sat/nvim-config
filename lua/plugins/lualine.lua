return {
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = { left = "⏐", right = "⏐" },
        section_separators = { left = " ", right = " " },
        globalstatus = true,
      },
    },
  },
}

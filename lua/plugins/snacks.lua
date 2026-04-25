return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      explorer = { enabled = false },
      dashboard = { enabled = false },
    },
    keys = {
      { "<leader>e", false },
      {
        "<leader>fp",
        function()
          require("snacks").picker.projects()
        end,
        desc = "Projects",
      },
    },
  },
}

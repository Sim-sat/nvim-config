-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function()
      return { "" }
    end,
    ["*"] = function()
      return { "" }
    end,
  },
}

return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.routes = opts.routes or {}
    -- pyright reports progress on every keystroke, which stacks up ✔ messages
    table.insert(opts.routes, {
      filter = {
        event = "lsp",
        kind = "progress",
        cond = function(message)
          return vim.tbl_get(message.opts, "progress", "client") == "pyright"
        end,
      },
      opts = { skip = true },
    })
  end,
}

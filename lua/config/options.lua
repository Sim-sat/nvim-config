vim.opt.clipboard = "unnamedplus"
vim.env.PATH = vim.env.PATH .. ":" .. "/home/simsat/.nvm/versions/node/v22.20.0/bin"
vim.opt.spell = false
vim.opt.list = false
vim.diagnostic.config({
  virtual_text = false,
})
vim.lsp.inlay_hint.enable(false)
vim.g.lazyvim_inlay_hints = false

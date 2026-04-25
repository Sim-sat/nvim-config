vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg and arg ~= "" then
      local stat = vim.loop.fs_stat(arg)
      if stat and stat.type == "directory" then
        vim.cmd.cd(arg) -- set the cwd correctly
        vim.cmd("bd") -- close the netrw/directory buffer
        require("dashboard"):instance() -- open dashboard
      end
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
  end,
})

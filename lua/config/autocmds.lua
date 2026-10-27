vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typst",
  callback = function()
    vim.opt_local.spelllang = { "de", "en" }
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

    -- tinymist checks each file standalone; pin the nearest main.typ so
    -- labels and @citations from included chapters resolve
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "tinymist" then
      local main = vim.fs.find("main.typ", {
        upward = true,
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf)),
      })[1]
      if main then
        client:exec_cmd({ title = "pin", command = "tinymist.pinMain", arguments = { main } }, { bufnr = args.buf })
      end
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  desc = "Attach keymaps for quickfix list",
  callback = function()
    vim.keymap.set("n", "dd", function()
      local qf_list = vim.fn.getqflist()

      local current_line_number = vim.fn.line(".")

      if qf_list[current_line_number] then
        table.remove(qf_list, current_line_number)

        vim.fn.setqflist(qf_list, "r")

        local new_line_number = math.min(current_line_number, #qf_list)
        vim.fn.cursor(new_line_number, 1)
      end
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = "Remove quickfix item under cursor",
    })
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

return {
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
      {
        "<leader>E",
        function()
          require("mini.files").open(vim.uv.cwd(), true)
        end,
        desc = "Open mini.files (cwd)",
      },
    },
  },
}

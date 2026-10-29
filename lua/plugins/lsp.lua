return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.diagnostics.virtual_text = false
    opts.inlay_hints = { enabled = false }

    opts.servers = opts.servers or {}
    opts.servers.gopls = opts.servers.gopls or {}
    -- Optimize gopls memory usage for large projects with generated code
    opts.servers.gopls.cmd_env = {
      GOMEMLIMIT = "2048MiB",
    }
    opts.servers.gopls.settings = opts.servers.gopls.settings or {}
    opts.servers.gopls.settings.gopls = opts.servers.gopls.settings.gopls or {}
    opts.servers.gopls.settings.gopls.memoryMode = "DegradeClosed"
    opts.servers.gopls.settings.gopls.usePlaceholders = false
  end,
}

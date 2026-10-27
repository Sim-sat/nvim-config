return {
  { "nvim-mini/mini.ai" },
  { "nvim-mini/mini-git" },
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
      local MiniGit = require("mini.git")
      MiniGit.setup()

      local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
      local autocmd = vim.api.nvim_create_autocmd
      local _, MiniFiles = pcall(require, "mini.files")

      local gitStatusCache = {}
      local cacheTimeout = 2000
      local uv = vim.uv or vim.loop

      local function isSymlink(path)
        local stat = uv.fs_lstat(path)
        return stat and stat.type == "link"
      end

      local function setupHighlights()
        vim.api.nvim_set_hl(0, "MiniFilesGitStaged", { fg = "#89b4fa" })
        vim.api.nvim_set_hl(0, "MiniFilesGitChange", { fg = "#fab387" })
        vim.api.nvim_set_hl(0, "MiniFilesGitDelete", { fg = "#f38ba8" })
        vim.api.nvim_set_hl(0, "MiniFilesGitUntrack", { fg = "#a6e3a1" })
        vim.api.nvim_set_hl(0, "MiniFilesGitIgnore", { fg = "#6c7086" })
      end
      setupHighlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setupHighlights })

      local function mapSymbols(status, is_symlink)
        local statusMap = {
          [" M"] = { symbol = "•", hlGroup = "MiniFilesGitChange" },
          ["M "] = { symbol = "✹", hlGroup = "MiniFilesGitChange" },
          ["MM"] = { symbol = "≠", hlGroup = "MiniFilesGitChange" },
          ["A "] = { symbol = "+", hlGroup = "MiniFilesGitStaged" },
          ["AA"] = { symbol = "≈", hlGroup = "MiniFilesGitStaged" },
          ["D "] = { symbol = "-", hlGroup = "MiniFilesGitDelete" },
          ["AM"] = { symbol = "⊕", hlGroup = "MiniFilesGitChange" },
          ["AD"] = { symbol = "-•", hlGroup = "MiniFilesGitChange" },
          ["R "] = { symbol = "→", hlGroup = "MiniFilesGitChange" },
          ["U "] = { symbol = "‖", hlGroup = "MiniFilesGitChange" },
          ["UU"] = { symbol = "⇄", hlGroup = "MiniFilesGitStaged" },
          ["UA"] = { symbol = "⊕", hlGroup = "MiniFilesGitStaged" },
          ["??"] = { symbol = "?", hlGroup = "MiniFilesGitUntrack" },
          ["!!"] = { symbol = "!", hlGroup = "MiniFilesGitIgnore" },
        }

        local result = statusMap[status] or { symbol = "?", hlGroup = "NonText" }
        local gitSymbol = result.symbol
        local gitHlGroup = result.hlGroup

        local symlinkSymbol = is_symlink and "↩" or ""

        local combinedSymbol = (symlinkSymbol .. gitSymbol):gsub("^%s+", ""):gsub("%s+$", "")
        local combinedHlGroup = is_symlink and "MiniFilesGitDelete" or gitHlGroup

        return combinedSymbol, combinedHlGroup
      end

      local function fetchGitStatus(cwd, callback)
        local clean_cwd = cwd:gsub("^minifiles://%d+/", "")
        local function on_exit(content)
          if content.code == 0 then
            callback(content.stdout)
          end
        end
        vim.system({ "git", "status", "--ignored", "--porcelain" }, { text = true, cwd = clean_cwd }, on_exit)
      end

      local function updateMiniWithGit(buf_id, gitStatusMap)
        vim.schedule(function()
          local nlines = vim.api.nvim_buf_line_count(buf_id)
          local cwd = vim.fs.root(buf_id, ".git")
          local escapedcwd = cwd and vim.pesc(cwd)
          escapedcwd = vim.fs.normalize(escapedcwd)

          for i = 1, nlines do
            local entry = MiniFiles.get_fs_entry(buf_id, i)
            if not entry then
              break
            end
            local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
            local status = gitStatusMap[relativePath]

            if status then
              local symbol, hlGroup = mapSymbols(status, isSymlink(entry.path))
              vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
                sign_text = symbol,
                sign_hl_group = hlGroup,
                priority = 2,
              })

              local line = vim.api.nvim_buf_get_lines(buf_id, i - 1, i, false)[1]
              local nameStartCol = line:find(vim.pesc(entry.name)) or 0

              if nameStartCol > 0 then
                vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, nameStartCol - 1, {
                  end_col = nameStartCol + #entry.name - 1,
                  hl_group = hlGroup,
                })
              end
            end
          end
        end)
      end

      local function parseGitStatus(content)
        local gitStatusMap = {}
        for line in content:gmatch("[^\r\n]+") do
          local status, filePath = string.match(line, "^(..)%s+(.*)")
          local parts = {}
          for part in filePath:gmatch("[^/]+") do
            table.insert(parts, part)
          end
          local currentKey = ""
          for i, part in ipairs(parts) do
            if i > 1 then
              currentKey = currentKey .. "/" .. part
            else
              currentKey = part
            end
            if i == #parts then
              gitStatusMap[currentKey] = status
            else
              if not gitStatusMap[currentKey] then
                gitStatusMap[currentKey] = status
              end
            end
          end
        end
        return gitStatusMap
      end

      local function updateGitStatus(buf_id)
        if not vim.fs.root(buf_id, ".git") then
          return
        end
        local cwd = vim.fs.root(buf_id, ".git")
        local currentTime = os.time()

        if gitStatusCache[cwd] and currentTime - gitStatusCache[cwd].time < cacheTimeout then
          updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
        else
          fetchGitStatus(cwd, function(content)
            local gitStatusMap = parseGitStatus(content)
            gitStatusCache[cwd] = {
              time = currentTime,
              statusMap = gitStatusMap,
            }
            updateMiniWithGit(buf_id, gitStatusMap)
          end)
        end
      end

      local function clearCache()
        gitStatusCache = {}
      end

      local function augroup(name)
        return vim.api.nvim_create_augroup("MiniFiles_" .. name, { clear = true })
      end

      autocmd("User", {
        group = augroup("start"),
        pattern = "MiniFilesExplorerOpen",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          updateGitStatus(bufnr)
        end,
      })

      autocmd("User", {
        group = augroup("close"),
        pattern = "MiniFilesExplorerClose",
        callback = function()
          clearCache()
        end,
      })

      autocmd("User", {
        group = augroup("update"),
        pattern = "MiniFilesBufferUpdate",
        callback = function(args)
          local bufnr = args.data.buf_id
          local cwd = vim.fs.root(bufnr, ".git")
          if gitStatusCache[cwd] then
            updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
          end
        end,
      })

      vim.keymap.set("n", "<leader>gs", function()
        MiniGit.show_at_cursor()
      end, { desc = "Git show at cursor" })

      vim.keymap.set("n", "<leader>gc", function()
        vim.cmd("Git commit")
      end, { desc = "Git commit" })

      vim.keymap.set("n", "<leader>gd", function()
        vim.cmd("Git diff")
      end, { desc = "Git diff" })

      vim.keymap.set("n", "<leader>gb", function()
        vim.cmd("Git blame")
      end, { desc = "Git blame" })

      vim.keymap.set("n", "<leader>gl", function()
        vim.cmd("Git log --oneline -20")
      end, { desc = "Git log" })

      vim.keymap.set("n", "<leader>gp", function()
        vim.cmd("Git push")
      end, { desc = "Git push" })

      vim.keymap.set("n", "<leader>ga", function()
        vim.system({ "git", "add", "-A" }, { text = true, cwd = vim.fs.root(0, ".git") }, function(result)
          vim.schedule(function()
            if result.code == 0 then
              vim.notify("git add -A done", vim.log.levels.INFO)
            else
              vim.notify("git add -A failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
            end
          end)
        end)
      end, { desc = "Git add all" })
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

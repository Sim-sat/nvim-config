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

      -- ── Highlight groups ───────────────────────────────────────────────
      local function setupHighlights()
        vim.api.nvim_set_hl(0, "MiniFilesGitStaged", { fg = "#89b4fa" }) -- blue
        vim.api.nvim_set_hl(0, "MiniFilesGitChange", { fg = "#fab387" }) -- orange
        vim.api.nvim_set_hl(0, "MiniFilesGitDelete", { fg = "#f38ba8" }) -- red
        vim.api.nvim_set_hl(0, "MiniFilesGitUntrack", { fg = "#a6e3a1" }) -- green
        vim.api.nvim_set_hl(0, "MiniFilesGitIgnore", { fg = "#6c7086" }) -- gray
      end
      setupHighlights()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setupHighlights })

      -- ── Git status integration ─────────────────────────────────────────
      local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
      local gitStatusCache = {}
      local uv = vim.uv or vim.loop

      local function isSymlink(path)
        local stat = uv.fs_lstat(path)
        return stat and stat.type == "link"
      end

      local function mapSymbols(status, is_symlink)
        local statusMap = {
          -- Staged → blue
          ["A "] = { symbol = "+", hlGroup = "MiniFilesGitStaged" },
          ["M "] = { symbol = "✹", hlGroup = "MiniFilesGitStaged" },
          ["D "] = { symbol = "-", hlGroup = "MiniFilesGitStaged" },
          ["R "] = { symbol = "→", hlGroup = "MiniFilesGitStaged" },
          ["C "] = { symbol = "©", hlGroup = "MiniFilesGitStaged" },
          -- Mixed staged+unstaged → orange
          ["MM"] = { symbol = "≠", hlGroup = "MiniFilesGitChange" },
          ["AM"] = { symbol = "⊕", hlGroup = "MiniFilesGitChange" },
          ["AD"] = { symbol = "-•", hlGroup = "MiniFilesGitChange" },
          ["MD"] = { symbol = "≠", hlGroup = "MiniFilesGitChange" },
          ["AA"] = { symbol = "≈", hlGroup = "MiniFilesGitChange" },
          -- Unstaged only → orange
          [" M"] = { symbol = "•", hlGroup = "MiniFilesGitChange" },
          -- Unstaged deletion → red
          [" D"] = { symbol = "-", hlGroup = "MiniFilesGitDelete" },
          -- Unmerged → red
          ["U "] = { symbol = "‖", hlGroup = "MiniFilesGitDelete" },
          ["UU"] = { symbol = "⇄", hlGroup = "MiniFilesGitDelete" },
          ["UA"] = { symbol = "⊕", hlGroup = "MiniFilesGitDelete" },
          ["DU"] = { symbol = "-‖", hlGroup = "MiniFilesGitDelete" },
          ["AU"] = { symbol = "+‖", hlGroup = "MiniFilesGitDelete" },
          ["DD"] = { symbol = "✕", hlGroup = "MiniFilesGitDelete" },
          -- Untracked → green
          ["??"] = { symbol = "?", hlGroup = "MiniFilesGitUntrack" },
          -- Ignored → gray
          ["!!"] = { symbol = "!", hlGroup = "MiniFilesGitIgnore" },
        }
        local result = statusMap[status] or { symbol = "?", hlGroup = "NonText" }
        local symlinkSymbol = is_symlink and "↩" or ""
        local combinedSymbol = (symlinkSymbol .. result.symbol):gsub("^%s+", ""):gsub("%s+$", "")
        local combinedHlGroup = is_symlink and "MiniFilesGitDelete" or result.hlGroup
        return combinedSymbol, combinedHlGroup
      end

      local function fetchGitStatus(cwd, callback)
        local clean_cwd = cwd:gsub("^minifiles://%d+/", "")
        vim.system({ "git", "status", "--ignored", "--porcelain" }, { text = true, cwd = clean_cwd }, function(content)
          if content.code == 0 then
            callback(content.stdout)
          end
        end)
      end

      local function parseGitStatus(content)
        local gitStatusMap = {}
        for line in content:gmatch("[^\r\n]+") do
          local status, filePath = string.match(line, "^(..)%s+(.*)")
          if status and filePath then
            filePath = filePath:match("^.* %-> (.+)$") or filePath
            local parts = {}
            for part in filePath:gmatch("[^/]+") do
              table.insert(parts, part)
            end
            local currentKey = ""
            for i, part in ipairs(parts) do
              currentKey = i == 1 and part or (currentKey .. "/" .. part)
              if i == #parts then
                gitStatusMap[currentKey] = status
              elseif not gitStatusMap[currentKey] then
                gitStatusMap[currentKey] = status
              end
            end
          end
        end
        return gitStatusMap
      end

      local function getOpenMiniBufs()
        return vim.tbl_filter(function(buf)
          return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "minifiles"
        end, vim.api.nvim_list_bufs())
      end

      local function updateMiniWithGit(buf_id, gitStatusMap)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_loaded(buf_id) then
            return
          end
          local nlines = vim.api.nvim_buf_line_count(buf_id)
          local cwd = vim.fs.root(buf_id, ".git")
          if not cwd then
            return
          end
          local escapedcwd = vim.fs.normalize(vim.pesc(cwd))

          for i = 1, nlines do
            local entry = require("mini.files").get_fs_entry(buf_id, i)
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

      local function fetchAndRefresh(cwd)
        fetchGitStatus(cwd, function(content)
          local gitStatusMap = parseGitStatus(content)
          gitStatusCache[cwd] = { statusMap = gitStatusMap }
          vim.schedule(function()
            for _, buf in ipairs(getOpenMiniBufs()) do
              if vim.fs.root(buf, ".git") == cwd then
                updateMiniWithGit(buf, gitStatusMap)
              end
            end
          end)
        end)
      end

      local function updateGitStatus(buf_id)
        local cwd = vim.fs.root(buf_id, ".git")
        if not cwd then
          return
        end
        fetchAndRefresh(cwd)
      end

      local function clearCache()
        gitStatusCache = {}
      end

      local function augroup(name)
        return vim.api.nvim_create_augroup("MiniFiles_" .. name, { clear = true })
      end

      vim.api.nvim_create_autocmd("User", {
        group = augroup("git_start"),
        pattern = "MiniFilesExplorerOpen",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          updateGitStatus(bufnr)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = augroup("git_close"),
        pattern = "MiniFilesExplorerClose",
        callback = clearCache,
      })

      vim.api.nvim_create_autocmd("User", {
        group = augroup("git_update"),
        pattern = "MiniFilesBufferUpdate",
        callback = function(args)
          local bufnr = args.data.buf_id
          local cwd = vim.fs.root(bufnr, ".git")
          if not cwd then
            return
          end
          if gitStatusCache[cwd] then
            updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
          else
            fetchAndRefresh(cwd)
          end
        end,
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup("git_write"),
        callback = function()
          local cwd = vim.fs.root(0, ".git")
          if not cwd then
            return
          end
          gitStatusCache[cwd] = nil
          fetchAndRefresh(cwd)
        end,
      })

      -- ── Wire mini.git events into mini.files refresh ───────────────────
      -- MiniGitUpdated fires whenever mini.git detects a repo state change
      -- (after any :Git command, git add, commit, checkout, etc.)
      -- This replaces the need for a filesystem watcher on .git/index
      vim.api.nvim_create_autocmd("User", {
        group = augroup("minigit_updated"),
        pattern = "MiniGitUpdated",
        callback = function(args)
          local cwd = args.data and args.data.git_dir
          if not cwd then
            return
          end
          -- git_dir points to .git/, we want the repo root
          cwd = vim.fn.fnamemodify(cwd, ":h")
          gitStatusCache[cwd] = nil
          fetchAndRefresh(cwd)
        end,
      })

      -- ── Key mappings ───────────────────────────────────────────────────
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          local mf = require("mini.files")
          vim.keymap.set("n", "<Left>", mf.go_out, { buffer = buf_id, desc = "Go out" })
          vim.keymap.set("n", "<Right>", mf.go_in, { buffer = buf_id, desc = "Go in" })
          vim.keymap.set("n", "q", mf.close, { buffer = buf_id, desc = "Close" })
          vim.keymap.set("n", "gc", function()
            local entry = mf.get_fs_entry()
            if not entry then
              return
            end
            local dir = entry.fs_type == "directory" and entry.path or vim.fn.fnamemodify(entry.path, ":h")
            vim.cmd.cd(dir)
            vim.notify("cwd: " .. dir)
            mf.open(dir, false)
          end, { buffer = buf_id, desc = "Set cwd and open" })
        end,
      })

      -- ── Global git keymaps ─────────────────────────────────────────────
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

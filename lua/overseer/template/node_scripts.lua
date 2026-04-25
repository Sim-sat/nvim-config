local ignored = { "preview", "build", "build:dev", "test:ci" }

return {
  generator = function(opts, cb)
    local package_json = vim.fn.findfile("package.json", vim.fn.getcwd() .. ";")
    if not package_json then
      cb({})
      return
    end

    local content = table.concat(vim.fn.readfile(package_json), "\n")
    local data = vim.fn.json_decode(content)

    if not data or not data.scripts then
      cb({})
      return
    end

    -- detect package manager
    local pm = "npm"
    if vim.fn.findfile("pnpm-lock.yaml", vim.fn.getcwd() .. ";") ~= "" then
      pm = "pnpm"
    elseif vim.fn.findfile("yarn.lock", vim.fn.getcwd() .. ";") ~= "" then
      pm = "yarn"
    end

    local tasks = {}
    for script_name, _ in pairs(data.scripts) do
      local skip = false
      for _, ig in ipairs(ignored) do
        if script_name == ig then
          skip = true
          break
        end
      end

      if not skip then
        table.insert(tasks, {
          name = pm .. ": " .. script_name,
          builder = function()
            return {
              cmd = { pm, "run", script_name },
              cwd = vim.fn.getcwd(),
            }
          end,
        })
      end
    end

    cb(tasks)
  end,
}

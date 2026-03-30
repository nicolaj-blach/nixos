return {
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "mail",
        callback = function()
          -- Only activate when reading from stdin (aerc pager)
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname ~= "" then
            return -- Not from stdin, skip
          end

          vim.keymap.set("n", "gx", function()
            local word = vim.fn.expand("<cWORD>")
            -- Check if it's a reference like [1] or [12]
            local ref = word:match("%[(%d+)%]")
            if ref then
              -- Search for the URL in References section
              local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
              for _, line in ipairs(lines) do
                local url = line:match("^%s*" .. ref .. "%.%s+(https?://%S+)")
                if url then
                  vim.ui.open(url)
                  return
                end
              end
              vim.notify("Reference [" .. ref .. "] not found", vim.log.levels.WARN)
            else
              -- Fallback: check if cursor is on a URL directly
              local url = word:match("https?://%S+")
              if url then
                vim.ui.open(url)
              else
                vim.notify("No link under cursor", vim.log.levels.WARN)
              end
            end
          end, { buffer = true, desc = "Open mail reference link" })
        end,
      })
    end,
  },
}

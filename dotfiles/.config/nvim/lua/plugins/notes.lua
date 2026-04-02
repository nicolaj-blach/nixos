-- Notes system configuration
-- Keybindings ONLY active when editing files in ~/notes/

local notes_path = vim.fn.expand("~/notes")

-- Helper: Get today's date in YYYY-MM-DD format
local function get_today()
  return os.date("%Y-%m-%d")
end

-- Helper: Add days to a date string
local function add_days(date_str, days)
  local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
  if not year then
    return nil
  end
  local time = os.time({ year = year, month = month, day = day })
  local new_time = time + (days * 24 * 60 * 60)
  return os.date("%Y-%m-%d", new_time)
end

-- Snooze function: increment review_date by 3 days
local function snooze_note()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local in_frontmatter = false
  local review_line_idx = nil
  local review_date = nil

  for i, line in ipairs(lines) do
    if line == "---" then
      if not in_frontmatter then
        in_frontmatter = true
      else
        break
      end
    elseif in_frontmatter then
      local date = line:match("^review_date:%s*(.+)$")
      if date then
        review_line_idx = i
        review_date = vim.trim(date)
        break
      end
    end
  end

  if not review_date then
    vim.notify("No review_date found in frontmatter", vim.log.levels.ERROR)
    return
  end

  local new_date = add_days(review_date, 3)
  if not new_date then
    vim.notify("Invalid date format: " .. review_date, vim.log.levels.ERROR)
    return
  end

  lines[review_line_idx] = "review_date: " .. new_date
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.notify("Snoozed to " .. new_date, vim.log.levels.INFO)
end

-- Note templates for LuaSnip
local function setup_snippets()
  local ok, ls = pcall(require, "luasnip")
  if not ok then
    return
  end

  local s = ls.snippet
  local t = ls.text_node
  local i = ls.insert_node
  local f = ls.function_node

  local today = function()
    return { get_today() }
  end

  ls.add_snippets("markdown", {
    s(";fleeting", {
      t({ "---", "tags: fleeting", "review_date: " }),
      f(today, {}),
      t({ "", "---", "", "# " }),
      i(1, "Title"),
      t({ "", "", "" }),
      i(0),
    }),
    s(";resource", {
      t({ "---", "tags: resource", "source: [[" }),
      i(1, "source"),
      t({ "]]", "---", "", "# " }),
      i(2, "Title"),
      t({ "", "", "" }),
      i(0),
    }),
    s(";atomic", {
      t({ "---", "tags: atomic", "up: [[" }),
      i(1, "parent"),
      t({ "]]", "---", "", "# " }),
      i(2, "Title"),
      t({ "", "", "" }),
      i(0),
    }),
    s(";project", {
      t({ "---", "tags: project", "status: active", "due: " }),
      f(today, {}),
      t({ "", "---", "", "# " }),
      i(1, "Project Name"),
      t({ "", "", "## Goals", "", "" }),
      i(2),
      t({ "", "", "## Tasks", "", "- [ ] " }),
      i(3),
      t({ "", "", "## Notes", "", "" }),
      i(0),
    }),
    s(";source", {
      t({ "---", "tags: source", "url: " }),
      i(1),
      t({ "", "---", "", "# " }),
      i(2, "Title"),
      t({ "", "", "## Summary", "", "" }),
      i(3),
      t({ "", "", "## Key Points", "", "" }),
      i(4),
      t({ "", "", "## Quotes", "", "" }),
      i(0),
    }),
  })
end

-- Folder mapping for note types
local folder_map = {
  fleeting = "f",
  resource = "r",
  atomic = "a",
  project = "p",
  source = "s",
}

-- Create new note with a specific name (used by picker)
local function create_note_with_name(note_type, name)
  local folder = folder_map[note_type]
  if not folder then
    vim.notify("Unknown note type: " .. note_type, vim.log.levels.ERROR)
    return
  end

  -- Clean up name for filename
  local filename = name:gsub("[^%w%s-]", ""):gsub("%s+", "-"):lower()
  local filepath = notes_path .. "/" .. folder .. "/" .. filename .. ".md"

  vim.fn.mkdir(notes_path .. "/" .. folder, "p")

  -- Write template directly to file
  local today = get_today()
  local template

  if note_type == "fleeting" then
    template = "---\ntags: fleeting\nreview_date: " .. today .. "\n---\n\n# " .. name .. "\n\n"
  elseif note_type == "resource" then
    template = "---\ntags: resource\nsource: [[]]\n---\n\n# " .. name .. "\n\n"
  elseif note_type == "atomic" then
    template = "---\ntags: atomic\nup: [[]]\n---\n\n# " .. name .. "\n\n"
  elseif note_type == "project" then
    template = "---\ntags: project\nstatus: active\ndue: "
      .. today
      .. "\n---\n\n# "
      .. name
      .. "\n\n## Goals\n\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n"
  elseif note_type == "source" then
    template = "---\ntags: source\nurl: \n---\n\n# "
      .. name
      .. "\n\n## Summary\n\n\n## Key Points\n\n\n## Quotes\n\n"
  else
    template = "# " .. name .. "\n\n"
  end

  -- Only write if file doesn't exist
  if vim.fn.filereadable(filepath) == 0 then
    local file = io.open(filepath, "w")
    if file then
      file:write(template)
      file:close()
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

-- Create new note with template auto-applied (prompts for name)
local function create_note(note_type)
  local folder = folder_map[note_type]
  if not folder then
    vim.notify("Unknown note type: " .. note_type, vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Note name: " }, function(name)
    if not name or name == "" then
      return
    end
    create_note_with_name(note_type, name)
  end)
end

-- Setup buffer-local keymaps ONLY for notes files
local function setup_notes_keymaps()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = vim.fn.expand("~/notes") .. "/**",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local opts = { buffer = bufnr }

      -- Register which-key group
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.add({
          { "<leader>;", group = "notes", icon = "", buffer = bufnr },
        })
      end

      -- Helper to get search text from picker
      local function get_picker_search(picker)
        local ok, result = pcall(function()
          local input_win = picker.input.win
          local input_buf = vim.api.nvim_win_get_buf(input_win)
          local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
          return lines[1] or ""
        end)
        return ok and result or ""
      end

      -- Helper to create note picker for a specific type
      local function note_picker(note_type, folder, title)
        require("snacks").picker.files({
          cwd = notes_path .. "/" .. folder,
          title = title,
          show_empty = true,
          auto_confirm = false,
          actions = {
            create_note = function(picker)
              -- Try different ways to get the search text
              local search_text = ""
              
              -- Try filter pattern
              if picker.filter and picker:filter().pattern then
                search_text = picker:filter().pattern
              end
              
              -- Try input:get()
              if search_text == "" and picker.input and picker.input.get then
                local ok, result = pcall(function() return picker.input:get() end)
                if ok and result then search_text = result end
              end
              
              -- Try getting from input buffer directly
              if search_text == "" and picker.input and picker.input.buf then
                local ok, lines = pcall(vim.api.nvim_buf_get_lines, picker.input.buf, 0, 1, false)
                if ok and lines and lines[1] then search_text = lines[1] end
              end
              
              picker:close()
              vim.defer_fn(function()
                if search_text ~= "" then
                  create_note_with_name(note_type, search_text)
                else
                  create_note(note_type)
                end
              end, 50)
            end,
            confirm_or_create = function(picker)
              local item = picker:current()
              if item then
                local file = item.file
                -- Ensure absolute path
                if not file:match("^/") then
                  file = notes_path .. "/" .. folder .. "/" .. file
                end
                picker:close()
                vim.defer_fn(function()
                  vim.cmd("edit " .. vim.fn.fnameescape(file))
                end, 10)
              else
                -- No match, create new note
                local search_text = get_picker_search(picker)
                picker:close()
                vim.defer_fn(function()
                  if search_text ~= "" then
                    create_note_with_name(note_type, search_text)
                  end
                end, 50)
              end
            end,
          },
          win = {
            input = {
              keys = {
                ["<CR>"] = { "confirm_or_create", mode = { "n", "i" }, desc = "Open or create note" },
                ["<S-CR>"] = { "create_note", mode = { "n", "i" }, desc = "Create new " .. note_type .. " note" },
              },
            },
            list = {
              keys = {
                ["<CR>"] = { "confirm_or_create", desc = "Open or create note" },
              },
            },
          },
        })
      end

      -- Note search keymaps using Snacks picker
      vim.keymap.set("n", "<leader>;f", function()
        note_picker("fleeting", "f", "Fleeting Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find fleeting notes" }))

      vim.keymap.set("n", "<leader>;a", function()
        note_picker("atomic", "a", "Atomic Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find atomic notes" }))

      vim.keymap.set("n", "<leader>;p", function()
        note_picker("project", "p", "Project Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find project notes" }))

      vim.keymap.set("n", "<leader>;r", function()
        note_picker("resource", "r", "Resource Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find resource notes" }))

      vim.keymap.set("n", "<leader>;o", function()
        note_picker("source", "s", "Source Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find source notes" }))

      vim.keymap.set("n", "<leader>;;", function()
        require("snacks").picker.files({
          cwd = notes_path,
          title = "All Notes",
        })
      end, vim.tbl_extend("force", opts, { desc = "Find all notes" }))

      vim.keymap.set("n", "<leader>;g", function()
        require("snacks").picker.grep({
          cwd = notes_path,
          title = "Grep Notes",
        })
      end, vim.tbl_extend("force", opts, { desc = "Grep in notes" }))

      -- Snooze
      vim.keymap.set("n", "<leader>;s", snooze_note, vim.tbl_extend("force", opts, { desc = "Snooze note (+3 days)" }))

      -- Open Inbox
      vim.keymap.set("n", "<leader>;i", function()
        vim.cmd("edit " .. vim.fn.fnameescape(notes_path .. "/Inbox.md"))
      end, vim.tbl_extend("force", opts, { desc = "Open Inbox" }))

      -- Create new note
      vim.keymap.set("n", "<leader>;n", function()
        vim.ui.select(
          { "fleeting", "atomic", "project", "resource", "source" },
          { prompt = "Note type:" },
          function(choice)
            if choice then
              create_note(choice)
            end
          end
        )
      end, vim.tbl_extend("force", opts, { desc = "New note" }))

      -- Toggle todo state
      vim.keymap.set("n", "<leader>;t", function()
        local line = vim.api.nvim_get_current_line()
        if line:match("%- %[ %]") then
          vim.api.nvim_set_current_line(line:gsub("%- %[ %]", "- [/]", 1))
        elseif line:match("%- %[/%]") then
          vim.api.nvim_set_current_line(line:gsub("%- %[/%]", "- [x]", 1))
        elseif line:match("%- %[x%]") then
          vim.api.nvim_set_current_line(line:gsub("%- %[x%]", "- [ ]", 1))
        end
      end, vim.tbl_extend("force", opts, { desc = "Toggle todo" }))

      -- Create link from clipboard
      vim.keymap.set("n", "<leader>;l", function()
        local clip = vim.fn.getreg("+")
        if clip and clip ~= "" then
          vim.api.nvim_put({ "[[" .. clip .. "]]" }, "c", true, true)
        end
      end, vim.tbl_extend("force", opts, { desc = "Link from clipboard" }))
    end,
  })
end

return {
  -- mkdnflow for wiki-link navigation and file creation
  {
    "jakewvincent/mkdnflow.nvim",
    ft = { "markdown" },
    opts = {
      modules = {
        bib = false,
        buffers = true,
        conceal = true,
        cursor = true,
        folds = false,
        foldtext = false,
        links = true,
        lists = true,
        maps = true,
        paths = true,
        tables = true,
        yaml = false,
      },
      filetypes = { markdown = true },
      create_dirs = true,
      perspective = {
        priority = "current",
        fallback = "first",
        root_tell = "index.md",
        nvim_wd_heel = false,
        update = true,
      },
      wrap = false,
      bib = {
        default_path = nil,
        find_in_root = false,
      },
      silent = false,
      cursor = {
        jump_patterns = nil,
      },
      links = {
        style = "wiki",
        compact = false,
        conceal = false,
        search_range = 0,
        implicit_extension = "md",
        transform_on_follow = false,
        transform_on_create = function(text)
          if text:match("/") then
            return text
          end
          return text:gsub(" ", "-"):lower()
        end,
        on_create_new = function(path, title)
          -- Create file with folder-specific template
          local today = get_today()
          local template

          if path:match("/f/") then
            template = "---\ntags: fleeting\nreview_date: "
              .. today
              .. "\n---\n\n# "
              .. (title or "Untitled")
              .. "\n\n"
          elseif path:match("/r/") then
            template = "---\ntags: resource\nsource: [[]]\n---\n\n# " .. (title or "Untitled") .. "\n\n"
          elseif path:match("/a/") then
            template = "---\ntags: atomic\nup: [[]]\n---\n\n# " .. (title or "Untitled") .. "\n\n"
          elseif path:match("/p/") then
            template = "---\ntags: project\nstatus: active\ndue: "
              .. today
              .. "\n---\n\n# "
              .. (title or "Untitled")
              .. "\n\n## Goals\n\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n"
          elseif path:match("/s/") then
            template = "---\ntags: source\nurl: \n---\n\n# "
              .. (title or "Untitled")
              .. "\n\n## Summary\n\n\n## Key Points\n\n\n## Quotes\n\n"
          else
            template = "# " .. (title or "Untitled") .. "\n\n"
          end

          -- Create parent directories if needed
          local dir = vim.fn.fnamemodify(path, ":h")
          vim.fn.mkdir(dir, "p")

          -- Write the template to the file
          local file = io.open(path, "w")
          if file then
            file:write(template)
            file:close()
          end

          return path
        end,
      },
      new_file_template = {
        enabled = false,
      },
      mappings = {
        MkdnEnter = { { "n", "v" }, "<CR>" },
        MkdnTab = false,
        MkdnSTab = false,
        MkdnNextLink = { "n", "<Tab>" },
        MkdnPrevLink = { "n", "<S-Tab>" },
        MkdnNextHeading = { "n", "]]" },
        MkdnPrevHeading = { "n", "[[" },
        MkdnGoBack = { "n", "<BS>" },
        MkdnGoForward = { "n", "<Del>" },
        MkdnCreateLink = false,
        MkdnCreateLinkFromClipboard = false,
        MkdnFollowLink = false,
        MkdnDestroyLink = false,
        MkdnTagSpan = false,
        MkdnMoveSource = false,
        MkdnYankAnchorLink = false,
        MkdnYankFileAnchorLink = false,
        MkdnIncreaseHeading = false,
        MkdnDecreaseHeading = false,
        MkdnToggleToDo = false,
        MkdnNewListItem = false,
        MkdnNewListItemBelowInsert = { "n", "o" },
        MkdnNewListItemAboveInsert = { "n", "O" },
        MkdnExtendList = false,
        MkdnUpdateNumbering = false,
        MkdnTableNextCell = { "i", "<Tab>" },
        MkdnTablePrevCell = { "i", "<S-Tab>" },
        MkdnTableNextRow = false,
        MkdnTablePrevRow = false,
        MkdnTableNewRowBelow = false,
        MkdnTableNewRowAbove = false,
        MkdnTableNewColAfter = false,
        MkdnTableNewColBefore = false,
        MkdnFoldSection = false,
        MkdnUnfoldSection = false,
      },
    },
  },

  -- Setup snippets and notes keymaps
  {
    "L3MON4D3/LuaSnip",
    config = function(_, opts)
      require("luasnip").setup(opts)
      setup_snippets()
      setup_notes_keymaps()
    end,
  },
}

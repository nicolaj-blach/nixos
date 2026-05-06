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

-- Helper: Parse frontmatter from file content
local function parse_frontmatter(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end

  local frontmatter = {}
  local in_frontmatter = false
  local line_count = 0

  for line in file:lines() do
    line_count = line_count + 1
    if line_count > 20 then
      break
    end

    if line == "---" then
      if not in_frontmatter then
        in_frontmatter = true
      else
        break
      end
    elseif in_frontmatter then
      local key, value = line:match("^([%w_]+):%s*(.*)$")
      if key and value then
        frontmatter[key] = vim.trim(value)
      end
    end
  end

  file:close()
  return frontmatter
end

-- Helper: Get notes with frontmatter data for dated pickers
local function get_notes_with_metadata(folder, date_field, exclude_status)
  local folder_path = notes_path .. "/" .. folder
  local items = {}

  local files = vim.fn.glob(folder_path .. "/*.md", false, true)

  for _, filepath in ipairs(files) do
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    if filename ~= "index" then
      local frontmatter = parse_frontmatter(filepath)

      -- Skip if status matches exclude_status
      if not (exclude_status and frontmatter.status == exclude_status) then
        local date_value = frontmatter[date_field] or "9999-99-99"

        table.insert(items, {
          file = filepath,
          name = filename,
          date = date_value,
          text = date_value .. " - " .. filename,
        })
      end
    end
  end

  table.sort(items, function(a, b)
    return a.date < b.date
  end)

  return items
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
    s(";reference", {
      t({ "---", "tags: reference", "source: " }),
      i(1),
      t({ "", "---", "", "# " }),
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

  })
end

-- Folder mapping for note types
local folder_map = {
  fleeting = "f",
  reference = "r",
  atomic = "a",
  project = "p",
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
  elseif note_type == "reference" then
    template = "---\ntags: reference\nsource: \n---\n\n# " .. name .. "\n\n"
  elseif note_type == "atomic" then
    template = "---\ntags: atomic\nup: [[]]\n---\n\n# " .. name .. "\n\n"
  elseif note_type == "project" then
    template = "---\ntags: project\nstatus: active\ndue: "
      .. today
      .. "\n---\n\n# "
      .. name
      .. "\n\n## Goals\n\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n"
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

-- Check if we're in a notes context (file in ~/notes OR cwd is ~/notes)
local function is_notes_context()
  local filepath = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  local notes_expanded = vim.fn.expand("~/notes")
  return filepath:find(notes_expanded, 1, true) == 1 or cwd:find(notes_expanded, 1, true) == 1
end

-- Setup buffer-local keymaps for notes context
local function setup_notes_keymaps()
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
      if not is_notes_context() then
        return
      end

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

      -- Helper to get search text from picker input
      local function get_picker_input(picker)
        local search_text = ""

        -- Try filter pattern
        if picker.filter and picker:filter().pattern then
          search_text = picker:filter().pattern
        end

        -- Try input:get()
        if search_text == "" and picker.input and picker.input.get then
          local ok, result = pcall(function()
            return picker.input:get()
          end)
          if ok and result then
            search_text = result
          end
        end

        -- Try getting from input buffer directly
        if search_text == "" and picker.input and picker.input.buf then
          local ok, lines = pcall(vim.api.nvim_buf_get_lines, picker.input.buf, 0, 1, false)
          if ok and lines and lines[1] then
            search_text = lines[1]
          end
        end

        return search_text
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
              local search_text = get_picker_input(picker)
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
                local search_text = get_picker_input(picker)
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

      -- Helper to create note picker with date display (for fleeting/project notes)
      local function dated_note_picker(note_type, folder, title, date_field, exclude_status)
        local today = get_today()
        local show_archived = false

        local function get_status_filter()
          if show_archived then
            return nil
          end
          return exclude_status
        end

        local function get_title()
          if show_archived and exclude_status then
            return title .. " (showing archived)"
          end
          return title
        end

        require("snacks").picker({
          title = get_title(),
          finder = function()
            return get_notes_with_metadata(folder, date_field, get_status_filter())
          end,
          format = function(item)
            local date = item.date
            local hl = nil
            if date < today then
              hl = "DiagnosticError" -- overdue: red
            elseif date == today then
              hl = "Statement" -- due today: purple
            end
            return { { item.text, hl } }
          end,
          show_empty = true,
          auto_confirm = false,
          actions = {
            create_note = function(picker)
              local search_text = get_picker_input(picker)
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
                picker:close()
                vim.defer_fn(function()
                  vim.cmd("edit " .. vim.fn.fnameescape(file))
                end, 10)
              else
                local search_text = get_picker_input(picker)
                picker:close()
                vim.defer_fn(function()
                  if search_text ~= "" then
                    create_note_with_name(note_type, search_text)
                  end
                end, 50)
              end
            end,
            toggle_archived = function(picker)
              show_archived = not show_archived
              picker.title = get_title()
              picker:find()
            end,
          },
          win = {
            input = {
              keys = {
                ["<CR>"] = { "confirm_or_create", mode = { "n", "i" }, desc = "Open or create note" },
                ["<S-CR>"] = { "create_note", mode = { "n", "i" }, desc = "Create new " .. note_type .. " note" },
                ["<a-a>"] = { "toggle_archived", mode = { "n", "i" }, desc = "Toggle archived" },
              },
            },
            list = {
              keys = {
                ["<CR>"] = { "confirm_or_create", desc = "Open or create note" },
                ["<a-a>"] = { "toggle_archived", desc = "Toggle archived" },
              },
            },
          },
        })
      end

      -- Note search keymaps using Snacks picker
      vim.keymap.set("n", "<leader>;f", function()
        dated_note_picker("fleeting", "f", "Fleeting Notes", "review_date")
      end, vim.tbl_extend("force", opts, { desc = "Find fleeting notes" }))

      vim.keymap.set("n", "<leader>;a", function()
        note_picker("atomic", "a", "Atomic Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find atomic notes" }))

      vim.keymap.set("n", "<leader>;p", function()
        dated_note_picker("project", "p", "Project Notes", "due", "archived")
      end, vim.tbl_extend("force", opts, { desc = "Find project notes" }))

      vim.keymap.set("n", "<leader>;r", function()
        note_picker("reference", "r", "Reference Notes")
      end, vim.tbl_extend("force", opts, { desc = "Find reference notes" }))

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
          { "fleeting", "atomic", "project", "reference" },
          { prompt = "Note type:" },
          function(choice)
            if choice then
              create_note(choice)
            end
          end
        )
      end, vim.tbl_extend("force", opts, { desc = "New note" }))

      -- Register which-key group for tables
      if wk_ok then
        wk.add({
          { "<leader>;t", group = "table", buffer = bufnr },
        })
      end

      -- Create link from clipboard
      vim.keymap.set("n", "<leader>;l", function()
        local clip = vim.fn.getreg("+")
        if clip and clip ~= "" then
          vim.api.nvim_put({ "[[" .. clip .. "]]" }, "c", true, true)
        end
      end, vim.tbl_extend("force", opts, { desc = "Link from clipboard" }))

      -- Table format (mkdnflow formats tables via :MkdnTable or cell navigation)
      vim.keymap.set("n", "<leader>;tf", "<cmd>MkdnTable<CR>", vim.tbl_extend("force", opts, { desc = "Format table" }))

      -- Backlinks: find notes that link to current note
      vim.keymap.set("n", "<leader>;b", function()
        local filename = vim.fn.expand("%:t:r") -- filename without extension
        -- Match [[filename]] or [[../a/filename]] etc, with optional alias or heading
        local pattern = "\\[\\[(\\.\\./[afrp]/)?" .. filename .. "(\\]\\]|\\||#)"
        -- Run rg and collect results, then show in picker without search field
        local results = {}
        local cmd = { "rg", "--line-number", "--column", "--no-heading", pattern, notes_path }
        vim.fn.jobstart(cmd, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            for _, line in ipairs(data) do
              if line ~= "" then
                local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
                if file then
                  table.insert(results, {
                    file = file,
                    line = tonumber(lnum),
                    col = tonumber(col),
                    text = text,
                  })
                end
              end
            end
          end,
          on_exit = function()
            vim.schedule(function()
              require("snacks").picker({
                title = "Backlinks to " .. filename,
                items = results,
                format = "file",
              })
            end)
          end,
        })
      end, vim.tbl_extend("force", opts, { desc = "Find backlinks" }))

      -- Delete current note
      vim.keymap.set("n", "<leader>;d", function()
        local filepath = vim.fn.expand("%:p")
        local filename = vim.fn.expand("%:t")

        vim.ui.input({ prompt = "Delete " .. filename .. "? [y/N] " }, function(input)
          if input and input:lower() == "y" then
            vim.fn.delete(filepath)
            vim.cmd("bdelete!")
            vim.cmd("bprevious")
            vim.notify("Deleted " .. filename, vim.log.levels.INFO)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Delete note" }))
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
            template = "---\ntags: reference\nsource: \n---\n\n# " .. (title or "Untitled") .. "\n\n"
          elseif path:match("/a/") then
            template = "---\ntags: atomic\nup: [[]]\n---\n\n# " .. (title or "Untitled") .. "\n\n"
          elseif path:match("/p/") then
            template = "---\ntags: project\nstatus: active\ndue: "
              .. today
              .. "\n---\n\n# "
              .. (title or "Untitled")
              .. "\n\n## Goals\n\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n"
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
        MkdnToggleToDo = { "n", "<C-x>" },
        MkdnNewListItem = false,
        MkdnNewListItemBelowInsert = { "n", "<leader>;o" },
        MkdnNewListItemAboveInsert = { "n", "<leader>;O" },
        MkdnExtendList = false,
        MkdnUpdateNumbering = false,
        MkdnTableNextCell = { "i", "<Tab>" },
        MkdnTablePrevCell = { "i", "<S-Tab>" },
        MkdnTableNextRow = false,
        MkdnTablePrevRow = false,
        MkdnTableNewRowBelow = { "n", "<leader>;tr" },
        MkdnTableNewRowAbove = false,
        MkdnTableNewColAfter = { "n", "<leader>;tc" },
        MkdnTableNewColBefore = false,
        MkdnFoldSection = false,
        MkdnUnfoldSection = false,
      },
    },
  },

  -- Disable Marksman diagnostics for non-existent links
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          -- Disable diagnostics from marksman (non-existent link warnings)
          handlers = {
            ["textDocument/publishDiagnostics"] = function() end,
          },
        },
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

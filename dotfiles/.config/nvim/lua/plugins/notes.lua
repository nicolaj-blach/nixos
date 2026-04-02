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

-- Create new note with template auto-applied
local function create_note(note_type)
  local folder_map = {
    fleeting = "fleeting",
    resource = "resources",
    atomic = "atomic",
    project = "projects",
    source = "sources",
  }

  local folder = folder_map[note_type]
  if not folder then
    vim.notify("Unknown note type: " .. note_type, vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Note name: " }, function(name)
    if not name or name == "" then
      return
    end

    name = name:gsub("[^%w%s-]", ""):gsub("%s+", "-"):lower()
    local filepath = notes_path .. "/" .. folder .. "/" .. name .. ".md"

    vim.fn.mkdir(notes_path .. "/" .. folder, "p")
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))

    local trigger = ";" .. note_type
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("i" .. trigger .. "<Tab>", true, false, true),
      "n",
      false
    )
  end)
end

-- Check if current buffer is in notes directory
local function is_notes_buffer()
  local bufpath = vim.fn.expand("%:p")
  return bufpath:sub(1, #notes_path) == notes_path
end

-- Setup buffer-local keymaps for a specific buffer
local function setup_buffer_keymaps(bufnr)
  local opts = { buffer = bufnr }

  -- Register which-key group
  local wk_ok, wk = pcall(require, "which-key")
  if wk_ok then
    wk.add({
      { "<leader>;", group = "notes", icon = "", buffer = bufnr },
    })
  end

  -- Note search keymaps using Snacks picker
  vim.keymap.set("n", "<leader>;f", function()
    require("snacks").picker.grep({
      cwd = notes_path,
      search = "tags: fleeting",
      title = "Fleeting Notes",
    })
  end, vim.tbl_extend("force", opts, { desc = "Find fleeting notes" }))

  vim.keymap.set("n", "<leader>;a", function()
    require("snacks").picker.grep({
      cwd = notes_path,
      search = "tags: atomic",
      title = "Atomic Notes",
    })
  end, vim.tbl_extend("force", opts, { desc = "Find atomic notes" }))

  vim.keymap.set("n", "<leader>;p", function()
    require("snacks").picker.grep({
      cwd = notes_path,
      search = "tags: project",
      title = "Project Notes",
    })
  end, vim.tbl_extend("force", opts, { desc = "Find project notes" }))

  vim.keymap.set("n", "<leader>;r", function()
    require("snacks").picker.grep({
      cwd = notes_path,
      search = "tags: resource",
      title = "Resource Notes",
    })
  end, vim.tbl_extend("force", opts, { desc = "Find resource notes" }))

  vim.keymap.set("n", "<leader>;o", function()
    require("snacks").picker.grep({
      cwd = notes_path,
      search = "tags: source",
      title = "Source Notes",
    })
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
end

-- Track which buffers already have keymaps set
local keymaps_set = {}

-- Setup buffer-local keymaps ONLY for notes files
local function setup_notes_keymaps()
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = "*",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Skip if already set up or not a notes file
      if keymaps_set[bufnr] then
        return
      end

      if not is_notes_buffer() then
        return
      end

      keymaps_set[bufnr] = true
      setup_buffer_keymaps(bufnr)
    end,
  })

  -- Clean up tracking when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    pattern = "*",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      keymaps_set[bufnr] = nil
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
      filetypes = { md = true, markdown = true },
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
        name_is_source = false,
        conceal = false,
        context = 0,
        implicit_extension = "md",
        transform_implicit = false,
        transform_explicit = function(text)
          if text:match("/") then
            return text
          end
          return text:gsub(" ", "-"):lower()
        end,
      },
      new_file_template = {
        use_template = true,
        placeholders = {
          before = {
            title = "link_title",
            date = "os_date",
          },
          after = {},
        },
        template = function()
          local bufpath = vim.fn.expand("%:p:h")
          local today = get_today()

          if bufpath:match("/fleeting$") or bufpath:match("/fleeting/") then
            return {
              "---",
              "tags: fleeting",
              "review_date: " .. today,
              "---",
              "",
              "# {{ title }}",
              "",
              "",
            }
          elseif bufpath:match("/resources$") or bufpath:match("/resources/") then
            return {
              "---",
              "tags: resource",
              "source: [[]]",
              "---",
              "",
              "# {{ title }}",
              "",
              "",
            }
          elseif bufpath:match("/atomic$") or bufpath:match("/atomic/") then
            return {
              "---",
              "tags: atomic",
              "up: [[]]",
              "---",
              "",
              "# {{ title }}",
              "",
              "",
            }
          elseif bufpath:match("/projects$") or bufpath:match("/projects/") then
            return {
              "---",
              "tags: project",
              "status: active",
              "due: " .. today,
              "---",
              "",
              "# {{ title }}",
              "",
              "## Goals",
              "",
              "",
              "## Tasks",
              "",
              "- [ ] ",
              "",
              "## Notes",
              "",
              "",
            }
          elseif bufpath:match("/sources$") or bufpath:match("/sources/") then
            return {
              "---",
              "tags: source",
              "url: ",
              "---",
              "",
              "# {{ title }}",
              "",
              "## Summary",
              "",
              "",
              "## Key Points",
              "",
              "",
              "## Quotes",
              "",
              "",
            }
          else
            return {
              "# {{ title }}",
              "",
              "",
            }
          end
        end,
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

  -- Setup snippets
  {
    "L3MON4D3/LuaSnip",
    config = function(_, opts)
      require("luasnip").setup(opts)
      setup_snippets()
      -- Initialize notes keymaps after plugins are loaded
      setup_notes_keymaps()
    end,
  },
}

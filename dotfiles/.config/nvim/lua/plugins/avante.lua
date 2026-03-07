return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "claude",
      providers = {
        claude = {
          model = "claude-opus-4-6",
        },
        ["claude-opus"] = {
          model = "claude-opus-4-6",
        },
        ["claude-sonnet"] = {
          __inherited_from = "claude",
          model = "claude-sonnet-4-6",
        },
        ["claude-haiku"] = {
          __inherited_from = "claude",
          model = "claude-haiku-4-5",
        },
        gemini = {
          __inherited_from = "gemini",
          model = "gemini-2.5-pro-preview-06-05",
        },
      },
    },
  },
}

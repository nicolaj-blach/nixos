return {
  -- Base16 colorscheme managed by tinty
  {
    "tinted-theming/tinted-vim",
    lazy = false,
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "base16-onedark",
    },
  },
}

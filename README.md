# scrawl.nvim

A utility to insert a quick doodle into a markdown document.

## Dependencies

- Neovim (>=v0.12.0)
- [scrawl](https://github.com/sof202/scrawl/)
    - If you don't already have this on `PATH`, the static binary will be
      downloaded (please note however that this static binary only works for
      linux-glibc-x86_64)
- Some kind of markdown previewer is also recommended (otherwise this is not
  particularly useful)

## Installation

As of neovim 0.12, `vim.pack` is the recommended way to install plugins. As
such, I'm not going to provide how to use packer or lazy.nvim (*etc.*).

```lua
vim.pack.add({
    { src = "https://github.com/sof202/scrawl.nvim" },
})
require("scrawl").setup()
```

## Configuration

```lua
require("scrawl").setup({
  keymaps = {
    markdown_insert = "<leader>mi"
  }
})
```

## Uninstalling

scrawl.nvim will download the `scrawl` binary to 
`vim.fn.stdpath(data)/scrawl.nvim/` (likely 
`$HOME/.local/share/nvim/scrawl.nvim/`). Remove this directory to completely
clean an installation.

One way you could do this is by running (in neovim):

```
:lua vim.fn.delete(vim.fn.stdpath(data).."/scrawl.nvim", "rf")
```

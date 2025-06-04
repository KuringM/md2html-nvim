# md2html.nvim

A lightweight Markdown → HTML converter for Neovim, with built-in MathJax support.

## ✨ Features

- Supports inline/block math (`$...$`, `$$...$$`) with MathJax
- Parses lists, tables, images, links, and footnotes
- Exports `.html` file from `.md` buffer via `:MdToHtml` command

## 📦 Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"kuringmin/md2html.nvim",
	cmd = "MdToHtml"
}
```

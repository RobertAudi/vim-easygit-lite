Easygit
=======

**The development of vim-gita has stopped. You should use [RobertAudi/git-blame.vim](https://github.com/RobertAudi/git-blame.vim) instead.**

A git wrapper plugin made to replace [fugitive](https://github.com/tpope/vim-fugitive), it can be used together with fugitive as commands are disabled by default.

The goal make cleaner code, and be more friendly to user (especially using with macvim)

Features
--------

- **Consist behaviour**, command always work in the git directory of current file
- **Clean code**, avoid madness hack like errorformat etc.
- **Friendly keymaping**, when enter temporary buffer precess `q` would help you to quit, no close window if opened by `edit` command
- **Expose flexible API**, in `autoload/easygit.vim`
- **Works good with other plugins** since filetype is nofile, your mru plugin and status line plugin should easily ignore them

Commands
--------

Commands are disabled by default, if you want to use them, you have to add this line to your `.vimrc`:

```vim
let g:easygit_enable_command = 1
```

- `Gblame`:          Git blame current file, you can use `p` to preview commit and `d` to diff with current file.
- `GdiffThis`:       Side by side diff of current file with head or any ref.

These commands have reasonable complete setting, use `<Tab>` to complete commands.

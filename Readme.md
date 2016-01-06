# Easygit

A git wrapper plugin made to replace [fugitive](https://github.com/tpope/vim-fugitive).
The goal is cleaner code, and be more friendly to user.

## Features

* *Consist behaviour*, command always work in the git directory of current file
* *Be quiet*, no ugly *press any key to continue*, and use dispatch method when
  possible
* *Clean code*, avoid madnes hack like errorformat etc.
* *Friendly keymaping*, when enter temporary buffer precess `q` would help you to
  quit, no close window if opened by `edit` command
* *Expose flexible API*, in `autoload/easygit.vim`
* *Works good with other plugins* since filetype is nofile, your mru plugin and
  status line plugin should easily ignore them, you can disable all commands
  with `let g:easygit_disable_command = 1` to make it works in fugitive.

## Commands

* *Gcd*             make vim cd to git root directory.
* *Glcd*            make vim lcd to git root directory.
* *Gblame*          Git blame current file, you can use `p` to preview commit and `d`
to diff with current file.
* *GcommitCurrent*  Git commit current file with message as command args.
* *GdiffThis*       Side by side diff of current file with head or any ref.
* *Gcommit*         Git commit with command line argument.
* *Gedit*           Edit git reference from git show.
* *Gdiff*           Git diff with command line argument.
* *Gremove*         Git remove with command line argument, remove current file
when arguments empty.
* *Grename*         Rename current by git mv, file in buffer list would reflex
  the changes.
* *Gmove*           Git mv with command line argument.
* *Gcheckout*       Git checkout with command line argument.
* *Gpush*           Git push with command line argument, dispatch when possible,
* *Gpull*           Git pull with command line argument, dispatch when possible,.
* *Gfetch*          Git fetch with command line argument, dispatch when possible,.

## Full documentation

See [doc/easygit.txt](https://github.com/chemzqm/vim-easygit/blob/master/doc/easygit.txt)

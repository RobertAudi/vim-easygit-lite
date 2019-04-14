" ============================================================================
" Description: Functions used by easygit
" Author: Qiming Zhao
" Maintainer: Robert Audi
" Licence: MIT licence
" Version: 0.7.0
" Last Modified: Apr 14, 2019
" ============================================================================

" Utility functions {{{
" ----------------------------------------------------------------------------

" Display an error message.
function! s:Error(msg) abort
  echohl ErrorMsg
  echon a:msg
  echohl NONE
endfunction

function! s:system(cmd) abort
  let l:output = system(a:cmd)

  if v:shell_error && l:output !=# ''
    call s:Error(l:output)

    return ''
  endif

  return l:output
endfunction

" Execute command and show the result by options:
"
"   `option.edit`      edit command used for open result buffer
"   `option.pipe`      pipe current buffer to command
"   `option.title`     required title for the new tmp buffer
"   `option.nokeep`    if 1, not keepalt
"
function! s:execute(cmd, option) abort
  let l:edit = get(a:option, 'edit', 'edit')
  let l:pipe = get(a:option, 'pipe', 0)
  let l:bnr = bufnr('%')

  if l:edit ==# 'pedit'
    let l:edit = 'new +setlocal\ previewwindow'
  endif

  if l:edit !~# 'keepalt' && !get(a:option, 'nokeep', 0)
    let l:edit = 'keepalt ' . l:edit
  endif

  if l:pipe
    let l:stdin = join(getline(1, '$'),"\n")
    let l:output = system(a:cmd, l:stdin)
  else
    let l:output = system(a:cmd)
  endif

  if v:shell_error && l:output !=# ''
    call s:Error(l:output)

    return -1
  endif

  execute l:edit . ' ' . a:option.title
  execute 'nnoremap <buffer> <silent> q :call <SID>SmartQuit("' . l:edit . '")<CR>'

  let b:easygit_prebufnr = l:bnr
  let l:list = split(l:output, '\v\r?\n')

  if len(l:list)
    call setline(1, l:list[0])
    silent! call append(1, l:list[1:])
  endif

  setlocal buftype=nofile readonly bufhidden=wipe
endfunction

function! s:sub(str, pat, rep) abort
  return substitute(a:str, '\v\C' . a:pat, a:rep, '')
endfunction

function! s:FindGitdir(path) abort
  if !empty($GIT_DIR)
    return $GIT_DIR
  endif

  if get(g:, 'easygit_enable_root_rev_parse', 1)
    let l:old_cwd = getcwd()
    let l:cwd = fnamemodify(a:path, ':p:h')

    execute 'lcd ' . l:cwd

    let l:root = system('git rev-parse --show-toplevel')

    execute 'lcd ' . l:old_cwd

    if v:shell_error
      return ''
    endif

    return substitute(l:root, '\r\?\n', '', '') . '/.git'
  else
    let l:dir = finddir('.git', expand(a:path) . ';')

    if empty(l:dir)
      return ''
    endif

    return fnamemodify(l:dir, ':p:h')
  endif
endfunction

function! s:NextCommit(commit, gitdir) abort
  let l:output = s:system('git --git-dir=' . a:gitdir
        \ . ' log --reverse --ancestry-path '
        \ . a:commit . '..master | head -n 1 | cut -d \  -f 2')

  return substitute(l:output, '\n', '', '')
endfunction

function! s:ShowNextCommit() abort
  let l:commit = matchstr(getline(1), '\v\s\zs.+$')
  let l:commit = s:NextCommit(l:commit, b:gitdir)

  if empty(l:commit)
    return
  endif

  call easygit#show(l:commit, {
        \   'edit': 'edit',
        \   'gitdir': b:gitdir,
        \   'all': 1,
        \ })
endfunction

function! s:ShowParentCommit() abort
  let l:commit = matchstr(getline(2), '\v\s\zs.+$')

  if empty(l:commit)
    return
  endif

  call easygit#show(l:commit, {
        \   'edit': 'edit',
        \   'gitdir': b:gitdir,
        \   'all': 1,
        \ })
endfunction

function! s:findObject(args) abort
  if !len(a:args)
    return 'head'
  endif

  let l:arr = split(a:args, '\v\s+')

  for l:str in l:arr
    if l:str !~# '\v^-'
      return l:str
    endif
  endfor

  return ''
endfunction

function! s:DiffFromBlame(bnr) abort
  let l:commit = matchstr(getline('.'), '^\^\=\zs\x\+')
  let l:wnr = bufwinnr(a:bnr)

  if l:wnr == -1
    execute 'silent b ' . a:bnr
  else
    execute l:wnr . 'wincmd w'
  endif

  call easygit#diffThis(l:commit)

  if l:wnr == -1
    let b:blame_bufnr = a:bnr
  endif
endfunction

function! s:ShowRefFromBlame(bnr) abort
  let l:commit = matchstr(getline('.'), '^\^\=\zs\x\+')
  let l:gitdir = easygit#gitdir(bufname(a:bnr))

  if empty(l:gitdir)
    return
  endif

  let l:root = fnamemodify(l:gitdir, ':h')
  let l:option = {
        \   'edit': 'split',
        \   'gitdir': l:gitdir,
        \   'all' : 1,
        \ }

  call easygit#show(l:commit, l:option)
endfunction

let s:hash_colors = {}
function! s:blameHighlight() abort
  let b:current_syntax = 'fugitiveblame'
  let l:conceal = has('conceal') ? ' conceal' : ''
  let l:arg = exists('b:fugitive_blame_arguments') ? b:fugitive_blame_arguments : ''

  syntax match EasygitblameBoundary "^\^"
  syntax match EasygitblameBlank                      "^\s\+\s\@=" nextgroup=EasygitblameAnnotation,fugitiveblameOriginalFile,EasygitblameOriginalLineNumber skipwhite
  syntax match EasygitblameHash       "\%(^\^\=\)\@<=\x\{7,40\}\>" nextgroup=EasygitblameAnnotation,EasygitblameOriginalLineNumber,fugitiveblameOriginalFile skipwhite
  syntax match EasygitblameUncommitted "\%(^\^\=\)\@<=0\{7,40\}\>" nextgroup=EasygitblameAnnotation,EasygitblameOriginalLineNumber,fugitiveblameOriginalFile skipwhite
  syntax region EasygitblameAnnotation matchgroup=EasygitblameDelimiter start="(" end="\%( \d\+\)\@<=)" contained keepend oneline
  syntax match EasygitblameTime "[0-9:/+-][0-9:/+ -]*[0-9:/+-]\%( \+\d\+)\)\@=" contained containedin=EasygitblameAnnotation

  execute 'syntax match EasygitblameLineNumber         " *\d\+)\@=" contained containedin=EasygitblameAnnotation' . l:conceal
  execute 'syntax match EasygitblameOriginalFile       " \%(\f\+\D\@<=\|\D\@=\f\+\)\%(\%(\s\+\d\+\)\=\s\%((\|\s*\d\+)\)\)\@=" contained nextgroup=EasygitblameOriginalLineNumber,EasygitblameAnnotation skipwhite' . (l:arg =~# 'f' ? '' : l:conceal)
  execute 'syntax match EasygitblameOriginalLineNumber " *\d\+\%(\s(\)\@=" contained nextgroup=EasygitblameAnnotation skipwhite' . (l:arg =~# 'n' ? '' : l:conceal)
  execute 'syntax match EasygitblameOriginalLineNumber " *\d\+\%(\s\+\d\+)\)\@=" contained nextgroup=EasygitblameShort skipwhite' . (l:arg =~# 'n' ? '' : l:conceal)

  syntax match EasygitblameShort              " \d\+)" contained contains=EasygitblameLineNumber
  syntax match EasygitblameNotCommittedYet "(\@<=Not Committed Yet\>" contained containedin=EasygitblameAnnotation

  highlight def link EasygitblameBoundary           Keyword
  highlight def link EasygitblameHash               Identifier
  highlight def link EasygitblameUncommitted        Ignore
  highlight def link EasygitblameTime               PreProc
  highlight def link EasygitblameLineNumber         Number
  highlight def link EasygitblameOriginalFile       String
  highlight def link EasygitblameOriginalLineNumber Float
  highlight def link EasygitblameShort              EasygitblameDelimiter
  highlight def link EasygitblameDelimiter          Delimiter
  highlight def link EasygitblameNotCommittedYet    Comment

  let l:seen = {}
  for l:lnum in range(1, line('$'))
    let l:hash = matchstr(getline(l:lnum), '^\^\=\zs\x\{6\}')

    if l:hash ==# '' || l:hash ==# '000000' || has_key(l:seen, l:hash)
      continue
    endif

    let l:seen[l:hash] = 1
    let s:hash_colors[l:hash] = ''

    execute 'syntax match EasygitblameHash' . l:hash . '       "\%(^\^\=\)\@<=' . l:hash . '\x\{1,34\}\>" nextgroup=EasygitblameAnnotation,EasygitblameOriginalLineNumber,fugitiveblameOriginalFile skipwhite'
  endfor

  call s:RehighlightBlame()
endfunction

function! s:RehighlightBlame() abort
  for [l:hash, l:cterm] in items(s:hash_colors)
    if !empty(l:cterm) || has('gui_running')
      execute 'highlight EasygitblameHash' . l:hash . ' guifg=#' . l:hash.get(s:hash_colors, l:hash, '')
    else
      execute 'highlight link EasygitblameHash' . l:hash . ' Identifier'
    endif
  endfor
endfunction

function! s:SmartQuit(edit) abort
  let l:bnr = get(b:, 'blame_bufnr', '')

  if a:edit =~# 'edit'
    try
      execute 'b ' . b:easygit_prebufnr
    catch /.*/
      execute 'q'
    endtry
  else
    execute 'q'
  endif

  if !empty(l:bnr)
    call easygit#blame()
  endif
endfunction

" ---------------------------------------------------------------------------- }}}

" Extract git directory by path
" if suspend is given as a:1, no error message
function! easygit#gitdir(path, ...) abort
  let l:suspend = a:0 && a:1 != 0
  let l:path = resolve(fnamemodify(a:path , ':p'))
  let l:gitdir = s:FindGitdir(l:path)

  if empty(l:gitdir) && !l:suspend
    call s:Error('Git directory not found')
  endif

  return l:gitdir
endfunction

" If cwd inside current file git root, return cwd, otherwise return git root
function! easygit#smartRoot(...) abort
  let l:suspend = a:0 ? a:1 : 0
  let l:gitdir = easygit#gitdir(expand('%'), l:suspend)

  if empty(l:gitdir)
    return ''
  endif

  let l:root = fnamemodify(l:gitdir, ':h')
  let l:cwd = getcwd()

  return l:cwd =~# '^' . l:root ? l:cwd : l:root
endfunction

" Show the commit ref with `option.edit` and `option.all` using gitdir of current file
"
"   `option.file`      could contain the file for show
"   `option.fold`      if 0, open all folds
"   `option.all`       show all file changes
"   `option.gitdir`    could contain gitdir to work on
"
function! easygit#show(args, option) abort
  let l:fold = get(a:option, 'fold', 1)
  let l:gitdir = get(a:option, 'gitdir', '')

  if empty(l:gitdir)
    let l:gitdir = easygit#gitdir(expand('%'))
  endif

  if empty(l:gitdir)
    return
  endif

  let l:showall = get(a:option, 'all', 0)
  let l:format = "--pretty=format:'commit %H%nparent %P%nauthor %an <%ae> %ad%ncommitter %cn <%ce> %cd%n %e%n%n%s%n%n%b' "

  if l:showall
    let l:command = 'git --no-pager' . ' --git-dir=' . l:gitdir . ' show  --no-color ' . l:format . a:args
  else
    let l:root = fnamemodify(l:gitdir, ':h')
    let l:file = get(a:option, 'file', substitute(expand('%:p'), l:root . '/', '', ''))
    let l:command = 'git --no-pager' . ' --git-dir=' . l:gitdir . ' show --no-color ' . l:format . a:args . ' -- ' . l:file
  endif

  let l:opt = deepcopy(a:option)
  let l:opt.title = '__easygit__show__' . s:findObject(a:args) . (l:showall ? '' : '/' . fnamemodify(l:file, ':r')) . '__'
  let l:res = s:execute(l:command, l:opt)

  if l:res == -1
    return
  endif

  if l:fold
    setlocal foldenable
  endif

  setlocal filetype=git foldtext=easygit#foldtext() foldmethod=syntax

  let b:gitdir = l:gitdir

  call setpos('.', [bufnr('%'), 7, 0, 0])

  execute 'nnoremap <buffer> <silent> u :call <SID>ShowParentCommit()<CR>'
  execute 'nnoremap <buffer> <silent> d :call <SID>ShowNextCommit()<CR>'
endfunction

function! easygit#foldtext() abort
  if &foldmethod !=# 'syntax'
    return foldtext()
  elseif getline(v:foldstart) =~# '^diff '
    let [l:add, l:remove] = [-1, -1]
    let l:filename = ''

    for l:lnum in range(v:foldstart, v:foldend)
      if l:filename ==# '' && getline(l:lnum) =~# '^[+-]\{3\} [abciow12]/'
        let l:filename = getline(l:lnum)[6:-1]
      endif

      if getline(l:lnum) =~# '^+'
        let l:add += 1
      elseif getline(l:lnum) =~# '^-'
        let l:remove += 1
      elseif getline(l:lnum) =~# '^Binary '
        let l:binary = 1
      endif
    endfor

    if l:filename ==# ''
      let l:filename = matchstr(getline(v:foldstart), '^diff .\{-\} a/\zs.*\ze b/')
    endif

    if l:filename ==# ''
      let l:filename = getline(v:foldstart)[5:-1]
    endif

    if exists('binary')
      return 'Binary: ' . l:filename
    else
      return (l:add < 10 && l:remove < 100 ? ' ' : '') . l:add . '+ '
            \ . (l:remove < 10 && l:add < 100 ? ' ' : '') . l:remove . '- ' . l:filename
    endif
  elseif getline(v:foldstart) =~# '^# .*:$'
    let l:lines = getline(v:foldstart, v:foldend)

    call filter(l:lines, 'v:val =~# "^#\t"')
    call map(l:lines, 's:sub(v:val, "^#\t%(fixed: +|add: +)=", "")')
    call map(l:lines, 's:sub(v:val, "^([[:alpha:] ]+): +(.*)", "\\2 (\\1)")')

    return getline(v:foldstart) . ' ' . join(l:lines, ', ')
  endif

  return foldtext()
endfunction

" diff current file with ref in vertical split buffer
function! easygit#diffThis(ref, ...) abort
  let l:gitdir = easygit#gitdir(expand('%'))

  if empty(l:gitdir)
    return
  endif

  let l:ref = len(a:ref) ? a:ref : 'head'
  let l:edit = a:0 ? a:1 : 'vsplit'
  let l:ft = &filetype
  let l:bnr = bufnr('%')
  let l:root = fnamemodify(l:gitdir, ':h')
  let l:file = substitute(expand('%:p'), l:root . '/', '', '')
  let l:command = 'git --no-pager --git-dir='. l:gitdir . ' show --no-color ' . l:ref . ':' . l:file
  let l:option = {
        \   'edit': l:edit,
        \   'title': '__easygit__file__' . l:ref . '_' . fnamemodify(l:file, ':t')
        \ }

  diffthis

  let l:res = s:execute(l:command, l:option)

  if l:res == -1
    diffoff

    return
  endif

  execute 'setfiletype ' . l:ft

  diffthis

  let b:gitdir = l:gitdir

  setlocal foldenable

  call setwinvar(winnr(), 'easygit_diff_origin', l:bnr)
  call setpos('.', [bufnr('%'), 0, 0, 0])
endfunction

" Show diff content in preview window
function! easygit#diffPreview(args) abort
  let l:root = easygit#smartRoot()

  if empty(l:root)
    return
  endif

  let l:old_cwd = getcwd()

  execute 'silent lcd '. l:root

  let l:command = 'git --no-pager diff --no-color ' . a:args
  let l:temp = fnamemodify(tempname(), ':h') . '/' . fnamemodify(s:findObject(a:args), ':t')
  let l:cmd = ':silent !git --no-pager diff --no-color ' . a:args . ' > ' . l:temp . ' 2>&1'

  execute l:cmd
  execute 'silent lcd '. l:old_cwd
  silent execute 'pedit! ' . fnameescape(l:temp)

  wincmd P

  setlocal filetype=git foldmethod=syntax foldlevel=99
  setlocal foldtext=easygit#foldtext()
endfunction

" blame current file
function! easygit#blame(...) abort
  let l:edit = a:0 ? a:1 : 'edit'
  let l:root = easygit#smartRoot()

  if empty(l:root)
    return
  endif

  let l:cwd = getcwd()
  let l:bnr = bufnr('%')

  execute 'lcd ' . l:root

  let l:view = winsaveview()
  let l:cmd = 'git --no-pager blame -- ' . expand('%')
  let l:opt = {
        \   'edit': l:edit,
        \   'title': '__easygit__blame__',
        \ }
  let l:res = s:execute(l:cmd, l:opt)

  if l:res == -1
    return
  endif

  execute 'lcd ' . l:cwd

  setlocal filetype=easygitblame

  call winrestview(l:view)
  call s:blameHighlight()

  execute 'nnoremap <buffer> <silent> d :call <SID>DiffFromBlame(' . l:bnr . ')<CR>'
  execute 'nnoremap <buffer> <silent> p :call <SID>ShowRefFromBlame(' . l:bnr . ')<CR>'
endfunction

function! easygit#complete(file, branch, tag) abort
  let l:root = easygit#smartRoot()
  let l:output = ''
  let l:cwd = getcwd()

  execute 'lcd ' . l:root

  if a:file
    let l:output .= s:system('git ls-tree --name-only -r HEAD')
  endif

  if a:branch
    let l:output .= s:system('git branch --no-color -a | cut -c3- | sed ''s:^remotes\/::''')
  endif

  if a:tag
    let l:output .= s:system('git tag')
  endif

  exe 'lcd ' . l:cwd

  return l:output
endfunction

" Modeline {{{
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker : }}}

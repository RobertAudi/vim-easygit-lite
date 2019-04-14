if exists('g:did_easygit_loaded')
  finish
endif
let g:did_easygit_loaded = 1

" Restore diff status if no diff buffer open
function! s:Onbufleave()
  let l:wnr = +bufwinnr(+expand('<abuf>'))
  let l:val = getwinvar(l:wnr, 'easygit_diff_origin')

  if !len(l:val)
    return
  endif

  for l:i in range(1, winnr('$'))
    if l:i == l:wnr
      continue
    endif

    if len(getwinvar(l:i, 'easygit_diff_origin'))
      return
    endif
  endfor

  let l:wnr = bufwinnr(l:val)

  if l:wnr > 0
    execute l:wnr . 'wincmd w'

    diffoff
  endif
endfunction

function! s:DiffThis(arg)
  let l:ref = len(a:arg) ? a:arg : 'head'
  let l:edit = get(g:, 'easygit_diff_this_edit', 'vsplit')

  call easygit#diffThis(l:ref, l:edit)
endfunction

" File and Branch
function! s:CompleteDiffThis(A, L, P)
  return easygit#complete(1, 1, 0)
endfunction

augroup easygit
  autocmd!

  autocmd BufWinLeave __easygit__file* call s:Onbufleave()
augroup END

if get(g:, 'easygit_enable_command', 0)
  command! -nargs=0 Gblame call easygit#blame()
  command! -nargs=? -complete=custom,s:CompleteDiffThis GdiffThis call s:DiffThis(<q-args>)
endif

" Modeline {{{
" vim: set foldmarker={{{,}}} foldlevel=0 foldmethod=marker : }}}

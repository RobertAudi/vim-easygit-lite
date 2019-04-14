if exists('g:did_easygit_loaded') || v:version < 700
  finish
endif
let g:did_easygit_loaded = 1

" Restore diff status if no diff buffer open
function! s:Onbufleave()
  let wnr = +bufwinnr(+expand('<abuf>'))
  let val = getwinvar(wnr, 'easygit_diff_origin')
  if !len(val) | return | endif
  for i in range(1, winnr('$'))
    if i == wnr | continue | endif
    if len(getwinvar(i, 'easygit_diff_origin'))
      return
    endif
  endfor
  let wnr = bufwinnr(val)
  if wnr > 0
    exe wnr . "wincmd w"
    diffoff
  endif
endfunction

function! s:DiffThis(arg)
  let ref = len(a:arg) ? a:arg : 'head'
  let edit = get(g:, 'easygit_diff_this_edit', 'vsplit')
  call easygit#diffThis(ref, edit)
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
  command! -nargs=0 Gblame                         :call easygit#blame()
  command! -nargs=? -complete=custom,s:CompleteDiffThis  GdiffThis  :call s:DiffThis(<q-args>)
endif

"vim:set et sw=2 ts=2 tw=80 foldmethod=syntax fen:

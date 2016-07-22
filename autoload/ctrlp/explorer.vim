if get(g:, 'loaded_autoload_ctrlp_explorer')
  finish
endif
let g:loaded_autoload_ctrlp_explorer = 1
let s:save_cpo = &cpo
set cpo&vim

let g:ctrlp_ext_var = add(get(g:, 'ctrlp_ext_vars', []), {
      \ 'init': 'ctrlp#explorer#init()',
      \ 'accept': 'ctrlp#explorer#accept',
      \ 'lname': 'explorer extension',
      \ 'sname': 'explorer',
      \ 'type': 'path',
      \ 'nolim': 1
      \})
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#explorer#id() abort
  return s:id
endfunction

function! ctrlp#explorer#init(...) abort
  let s:cwd = fnamemodify(getcwd(), ":p")
  " ドットファイルを含む
  let s:list = map([".."] + glob(s:cwd . "/*", 0, 1) + glob(s:cwd . "/.??*", 0, 1), 'fnamemodify(v:val, ":t") . (isdirectory(v:val) ? "/" : "")')
  return s:list
endfunction

function! s:convert_path(path) abort
  " s:cwd CtrlPExplorer起動時のディレクトリ
  " ctrlp#exit()を呼ぶ前であれば，s:cwdの代わりにgetcwd()でも可
  let path = s:cwd . '/' . a:path
  return fnamemodify(simplify(path), ":p")
endfunction

function! ctrlp#explorer#accept(mode, str) abort
  call ctrlp#exit()
  let path = s:convert_path(a:str)
  if isdirectory(path)
    " cwdをpathに変更しCtrlPExplorerを起動
    call ctrlp#init(ctrlp#explorer#id(), {'dir': path})
  else
    call ctrlp#acceptfile(a:mode, path)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

if get(g:, 'loaded_autoload_ctrlp_explorer')
  finish
endif
let g:loaded_autoload_ctrlp_explorer = 1
let s:save_cpo = &cpo
set cpo&vim

let g:ctrlp_ext_var = add(get(g:, 'ctrlp_ext_vars', []), {
      \ 'init': 'ctrlp#explorer#init()',
      \ 'accept': 'ctrlp#explorer#accept',
      \ 'exit': 'ctrlp#explorer#exit()',
      \ 'lname': 'explorer extension',
      \ 'sname': 'explorer',
      \ 'type': 'path',
      \ 'nolim': 1
      \})
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#explorer#id() abort
  return s:id
endfunction

function! s:mapkey() abort
  nnoremap <buffer> <c-r> :call ctrlp#explorer#accept('r', ctrlp#getcline())<cr>
endfunction

function! s:unmapkey() abort
  if mapcheck('<c-r>', 'n') !=# ''
    nunmap <buffer> <c-r>
  endif
endfunction

function! ctrlp#explorer#init(...) abort
  call s:mapkey()
  let s:cwd = fnamemodify(getcwd(), ":p")
  " ドットファイルを含む
  " WindowsとMacで結果が異なるため，新しいglobパターンが必要
  " Windowsでは，'./', '../' の2つが，glob(s:cwd . "/.??*", 0, 1) によって余計に含まれてしまう
  let filelist = map([".."] + glob(s:cwd . "/*", 0, 1) + glob(s:cwd . "/.??*", 0, 1), 'fnamemodify(v:val, ":t") . (isdirectory(v:val) ? "/" : "")')
  return filelist
endfunction

function! s:convert_path(path) abort
  " s:cwd CtrlPExplorer起動時のディレクトリ
  " ctrlp#exit()を呼ぶ前であれば，s:cwdの代わりにgetcwd()でも可
  let path = s:cwd . '/' . a:path
  return fnamemodify(simplify(path), ":p")
endfunction

function! s:rename_file(target_path) abort
  let target_dir = fnamemodify(a:target_path, ':p:h')
  let target_filename = fnamemodify(a:target_path, ':p:t')
  let new_filename = input('filename: ', target_filename)
  let new_path = target_dir . '/' . new_filename
  call rename(a:target_path, new_path)
endfunction

function! s:accept(mode, path) abort
  let open_func_dic = get(g:, 'ctrlp_open_func', {})
  let open_func = get(open_func_dic, 'files', 'ctrlp#acceptfile')
  call call(open_func, [a:mode, a:path])
endfunction

function! ctrlp#explorer#accept(mode, str) abort
  call ctrlp#exit()
  let path = s:convert_path(a:str)
  if isdirectory(path)
    " cwdをpathに変更しCtrlPExplorerを起動
    call ctrlp#init(ctrlp#explorer#id(), {'dir': path})
    return
  endif
  if a:mode ==# 'r'
    call s:rename_file(path)
    call ctrlp#init(ctrlp#explorer#id(), {'dir': s:cwd})
    return
  endif
  call s:accept(a:mode, path)
endfunction

function! ctrlp#explorer#exit() abort
  call s:unmapkey()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

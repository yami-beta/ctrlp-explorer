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
  nnoremap <buffer> <c-d> :call ctrlp#explorer#accept('d', ctrlp#getcline())<cr>
  nnoremap <buffer> <c-y> :call ctrlp#explorer#accept('y', ctrlp#getcline())<cr>
endfunction

function! s:unmapkey() abort
  if mapcheck('<c-r>', 'n') !=# ''
    nunmap <buffer> <c-r>
  endif
  if mapcheck('<c-d>', 'n') !=# ''
    nunmap <buffer> <c-d>
  endif
  if mapcheck('<c-y>', 'n') !=# ''
    nunmap <buffer> <c-y>
  endif
endfunction

function! ctrlp#explorer#init(...) abort
  call s:mapkey()
  let s:cwd = fnamemodify(getcwd(), ":p")
  " Glob pattern for include dot files (e.g. .vimrc)
  let filelist = map([".."] + glob(s:cwd."/*", 0, 1) + glob(s:cwd."/.[^.]*", 0, 1), 'fnamemodify(v:val, ":t") . (isdirectory(v:val) ? "/" : "")')
  return filelist
endfunction

function! s:convert_path(path) abort
  " s:cwd CtrlPExplorer起動時のディレクトリ
  " ctrlp#exit()を呼ぶ前であれば，s:cwdの代わりにgetcwd()でも可
  let path = s:cwd . '/' . a:path
  return fnamemodify(simplify(path), ":p")
endfunction

function! s:get_ctrlp_script_id()
  let snlist = execute('scriptnames')
  for line in split(snlist, "\n")
    if line =~ 'autoload\/ctrlp\.vim$'
      let sid = matchstr(line, '^[0-9]\+')
      return sid
    endif
  endfor
endfunction

function! ctrlp#explorer#getinput() abort
  let sid = s:get_ctrlp_script_id()
  return function('<SNR>'.sid.'_getinput')()
endfunction

function! s:create_file_or_directory(prompt_input) abort
  let mode = get(g:, 'ctrlp_open_new_file', 'e')
  let target_path = fnamemodify(s:cwd.a:prompt_input, ':p')
  if a:prompt_input =~ '\/$'
    call mkdir(target_path)
    call ctrlp#init(ctrlp#explorer#id(), {'dir': s:cwd})
    return
  endif
  call s:accept(mode, target_path)
endfunction

function! s:rename_file_or_directory(target_path) abort
  let parent_dir = fnamemodify(a:target_path, ':p:h')
  let target_name = fnamemodify(a:target_path, ':p:t')
  let label = 'filename: '
  if isdirectory(a:target_path)
    let parent_dir = fnamemodify(parent_dir, ':h')
    let target_name = fnamemodify(a:target_path, ':p:h:t')
    let label = 'directory name: '
  endif
  let new_name = input(label, target_name)
  let new_path = parent_dir . '/' . new_name
  call rename(a:target_path, new_path)
endfunction

function! s:delete_file_or_directory(target_path) abort
  let target_path = fnamemodify(a:target_path, ':p')
  let target_name = fnamemodify(target_path, ':t')
  let is_directory = isdirectory(target_path)
  if is_directory
    let target_name = fnamemodify(target_path, ':p:h:t')
  endif
  let do_delete = confirm('Delete '.target_name.' ? (y/n)', "&yes\n&no", 0)
  if do_delete ==# 1
    let result = delete(target_path, is_directory ? 'd' : '')
    if result !=# 0
      echohl WarningMsg
      echomsg 'Failed to delete '.target_name
      echohl None
    endif
  endif
endfunction

function! s:accept(mode, path) abort
  let open_func_dic = get(g:, 'ctrlp_open_func', {})
  let open_func = get(open_func_dic, 'files', 'ctrlp#acceptfile')
  call call(open_func, [a:mode, a:path])
endfunction

function! ctrlp#explorer#accept(mode, str) abort
  let prompt_input = ctrlp#explorer#getinput()
  call ctrlp#exit()
  let path = s:convert_path(a:str)
  if a:mode ==# 'y'
    call s:create_file_or_directory(prompt_input)
    return
  endif
  if a:mode ==# 'r'
    call s:rename_file_or_directory(path)
    call ctrlp#init(ctrlp#explorer#id(), {'dir': s:cwd})
    return
  endif
  if a:mode ==# 'd'
    call s:delete_file_or_directory(path)
    call ctrlp#init(ctrlp#explorer#id(), {'dir': s:cwd})
    return
  endif

  if isdirectory(path)
    " cwdをpathに変更しCtrlPExplorerを起動
    call ctrlp#init(ctrlp#explorer#id(), {'dir': path})
    return
  endif
  call s:accept(a:mode, path)
endfunction

function! ctrlp#explorer#exit() abort
  call s:unmapkey()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

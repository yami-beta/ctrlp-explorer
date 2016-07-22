if get(g:, 'loaded_ctrlp_explorer')
  finish
endif
let g:loaded_ctrlp_explorer = 1
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? -complete=dir CtrlPExplorer call ctrlp#init(ctrlp#explorer#id(), {'dir': <q-args>})

let &cpo = s:save_cpo
unlet s:save_cpo

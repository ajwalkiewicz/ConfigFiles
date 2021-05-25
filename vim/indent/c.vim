set exrc
set secure

set colorcolumn=80
set smartindent

set tabstop=4
set softtabstop=4
set shiftwidth=4
set noexpandtab

autocmd FileType apache setlocal commentstring=//\ %s

autocmd BufRead,BufNewFile *.h,*.c set filetype=c.doxygen

" vertical column line
set cursorcolumn
set cursorline

" Kite settings
let g:kite_supported_languages = ['c']
set statusline=%<%f\ %h%m%r%{kite#statusline()}%=%-14.(%l,%c%V%)\ %P
set laststatus=2
" %{kite#statusline()}
let g:kite_tab_complete=1
set completeopt-=preview " show the documentation prewiew window
set completeopt+=menuone
set completeopt+=noinsert


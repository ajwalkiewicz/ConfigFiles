set colorcolumn=80
set smartindent
" Kite settings
let g:kite_supported_languages = ['python']
set statusline=%<%f\ %h%m%r%{kite#statusline()}%=%-14.(%l,%c%V%)\ %P
set laststatus=2
" %{kite#statusline()}
let g:kite_tab_complete=1
set completeopt-=preview " show the documentation prewiew window
set completeopt+=menuone
set completeopt+=noinsert

" formating yapf
" let maplocalleader="\<space>"
autocmd FileType python nnoremap <leader>= :!yapf % -i --style=pep8<CR>
set autoread

" highlighting
" hi pythonSelf  ctermfg=68  guifg=#5f87d7 cterm=bold gui=bold

" Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

" Exit Vim if NERDTree is the only window left.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

" tagbar - code browser
nmap <F8> :TagbarToggle<CR>
autocmd VimEnter * TagbarToggle

" autocmd VimEnter * :!/home/walu/.local/share/kite/current/linux-unpacked/kite &
" Kite
" autocmd FileType python nnoremap <leader>K :!/home/walu/.local/share/kite/current/linux-unpacked/kite &<CR>
"
" Commentary - set # for coments in python
autocmd FileType apache setlocal commentstring=#\ %s

" run python on the current script
nmap ,p :w<CR>:!python3 %<CR>

" highlightning python syntax
let python_highlight_all = 1

" python docstrings
let g:pydocstring_formatter = 'sphinx'
" g:/home/walu/anaconda3/bin/doq
nmap <leader>d :Pydocstring<CR>

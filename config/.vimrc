syntax enable
" awesome colorcheme
colorscheme molokai
" colorscheme gruvebox
" colorscheme PaperColor
" colorscheme  monokai_pro
let g:molokai_original = 1
" set colorescheme monokai_pro
set background=dark

set tabstop=4           " number of visual spaces per TAB
set softtabstop=4       " number of spaces in tab when edition
set expandtab           " tabs are spaces

" UI config
" set number            " show line numbers
set number relativenumber      " show relative numbers
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
filetype indent on      " load filetype-specifiv indent files, eg /.vim/indent/python.vim
set wildmenu            " visual autocomplete for command menu
set lazyredraw          " redraw only when we need to
set showmatch           " highlight matching [{()}]
set scrolloff=5         " scrollf of from top and bottom set to X lines

set incsearch           " search as characters are entered
set hlsearch            " highlight matches

" let mapleader = "-"     " set leader key to '-'
let mapleader = " "    " set leader key to SPC
" turn off search highlight '-'+space
nnoremap <leader><space> :nohlsearch<CR> 

" set ruler               " set ruler
"set columns=80
"set colorcolumn=80
set encoding=utf-8      " set encoding to utf-8
set noswapfile          " disable .swp files

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle (plugin meneger) set up 
set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

Plugin 'scrooloose/nerdtree'     " file tree pluign
Plugin 'majutsushi/tagbar'       " code browser
Plugin 'vim-airline/vim-airline' " simple powerline
Plugin 'airblade/vim-gitgutter'  " shows git diff
Plugin 'tpope/vim-commentary'    " add comments option
" Plugin 'mhinz/vim-startify'    " add starting page to vim
" Plugin 'junegunn/fzf'          " fuzzy finder in vim
Plugin 'hdima/python-syntax'     " python syntac coloring
" Plugin 'mg979/vim-visual-multi' " muliple cursors for vim
" Plugin 'terryma/vim-multiple-cursors' " another multiple cursor for vim
Plugin 'iamcco/markdown-preview.nvim' " preview for markdown fileo
" Plugin 'JamshedVesuna/vim-markdown-preview' " another markdown preview
Plugin 'heavenshell/vim-pydocstring' " docstrings for python
Plugin 'Yggdroot/indentLine'     " indentation lines
Plugin 'Syntastic'               " Syntax checker
Plugin 'tpope/vim-surround'      " support for surroundings
Plugin 'christoomey/vim-system-copy' " copy paste, require xsel
" Plugin 'jceb/vim-orgmode'        " emacs orgmode for vim

" Color Themes
" Plugin 'phanviet/vim-monokai-pro' " monokai theme
" Plugin 'NLKNguyen/papercolor-theme' " papercolor theme


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set updatetime=100 " refresh time, for vim-gutter to work faster 

" Markdown preview options
" normal/insert
" <Plug>MarkdownPreview
" <Plug>MarkdownPreviewStop
" <Plug>MarkdownPreviewToggle

" example
nmap <C-s> <Plug>MarkdownPreview
nmap <M-s> <Plug>MarkdownPreviewStop
nmap <C-p> <Plug>MarkdownPreviewToggle

" NERDtree - file menager
nnoremap <leader>n :NERDTreeFocus<CR>
" nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" Navigation between split windows
nnoremap <C-h> <C-w>h 
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" Disabling default pydocstring biding
let g:pydocstring_enable_mapping = 0

" Navigation between buffers
" nnoremap <PageUp> :bn<CR>
" nnoremap <PageDown> :bp<CR>
" Navigation between tabs
nnoremap <PageUp> :tabn<CR>
nnoremap <PageDown> :tabp<CR>

" buffer reloads
nnoremap <leader>br :edit!<CR>

" Air-line
let g:airline#extensions#tabline#enabled = 1 " setting tabline

" Settings for C
" autocmd BufRead,BufNewFile *.h,*.c set filetype=c.doxygen

" Tagbar settings
map <F8> :TagbarToggle<CR>

" Splitting windows
set splitbelow splitright
" Make adjusing split sizes a bit more friendly
noremap <silent> <C-Left> :vertical resize +1<CR>
noremap <silent> <C-Right> :vertical resize -1<CR>
noremap <silent> <C-Up> :resize -1<CR>
noremap <silent> <C-Down> :resize +1<CR>
" Change 2 split windows from vert to horiz or horiz to vert
map <Leader>th <C-w>t<C-w>H
map <Leader>tk <C-w>t<C-w>K


" Terminal settings
" map <Leader>tp :new term://bash<CR>python3<CR><C-\><C-n><C-w>k
map <Leader>tb :below terminal<CR>
map <Leader>ta :above terminal<CR>
set termwinsize=10x0

" python syntax xoloring
let python_highlight_all = 1

" Accecing system clipboard
" set clipboard=unnamedplus
set clipboard=unnamed

" Syntaxtic settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
" My modifications
let g:syntastic_error_symbol = "E>"
let g:syntastic_warning_symbol = "W>"

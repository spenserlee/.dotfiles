" VIM settings which should just be default
" Using neovim, but keeping the basics in vim script for easy copying to other
" devices

" --- general
filetype plugin indent on
let mapleader = " "
syntax on

set hidden                              " allow background buffers
set autoread                            " update files if changed externally
set history=10000                       " command history
set undofile                            " save mistakes
set clipboard=unnamedplus               " use system clipboard
set noerrorbells                        " silence!
set mouse=n                             " use mouse in normal mode
set backspace=indent,eol,start          " backspace acts sensibly

" --- ui
scriptencoding utf-8                    " needed for listchars on windows
set encoding=utf-8                      " language encoding
"set cursorline                          " highlight current line
set title                               " show what's open
set ruler                               " always show current position
set showcmd                             " display command typed
set cmdheight=1                         " height of command bar
set scrolloff=3                         " buffer line space when scrolling up/down
set sidescrolloff=5                     " buffer line space when scrolling left/right
set relativenumber                      " line numbers relative to cursor
set number                              " show absolute line numbers
set textwidth=80                        " show the 80th column
set colorcolumn=+1"
set hlsearch                            " highlight search results
set splitbelow                          " new panes appear more natural
set splitright
set background=dark

" --- text formatting
set ignorecase                          " ignore case when searching
set smartcase                           " when searching try to be smart
set smarttab                            " be smart about tabbing
set nowrap                              " wrap text
set expandtab                           " tabs = spaces
set shiftwidth=4                        " 1 tab == 4 spaces as it should be
set tabstop=4
set ai                                  " auto indent
set si                                  " smart indent
set list                                " visualize whitespace
set listchars=tab:→→,trail:⋅,nbsp:⋅     " characters to show

" --- misc
" Use relative numbers by default (normal/visual), but absolue in insert mode
autocmd! BufLeave,FocusLost,InsertEnter   * setlocal norelativenumber
autocmd! BufEnter,FocusGained,InsertLeave * setlocal relativenumber

" return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" --- key mappings

" quickfix managment
function! ToggleQuickfix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
command! ClearQuickfixList cexpr []

noremap <leader>q :call ToggleQuickfix()<cr>
noremap <leader>Q :ClearQuickfixList<cr>

noremap ]q :cnext<cr>
noremap [q :cprev<cr>

noremap [Q :cfirst<cr>
noremap ]Q :clast<cr>

" disable ex mode
noremap Q <NOP>

" Move up/down lines visually when wrapped
nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')

" Leader+h clears search highlighting
map <silent> <Leader>h :noh<CR>

" Count occurrences of previous search
" https://vi.stackexchange.com/a/100
nnoremap <leader>C :%s///gn<CR>

" jump to next brace usually want the function to occupy most of screen
nnoremap ]] ]]zt
nnoremap [[ [[zt

" TAB for quick buffer navigation
nnoremap <TAB> :bnext<CR>
nnoremap <S-TAB> :bprevious<CR>

" Close this buffer, but don't close the split or window
" noremap <leader>d :bprevious\|bdelete #<CR>
nnoremap <leader>d :bdelete<CR>

" tab management
nnoremap R :tabprevious<CR>
nnoremap T :tabnext<CR>
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" window navigation
nnoremap <M-j> <C-W>j
nnoremap <M-k> <C-W>k
nnoremap <M-h> <C-W>h
nnoremap <M-l> <C-W>l

" window resizing
" nnoremap <C-j> :resize -2<CR>
" nnoremap <C-k> :resize +2<CR>
" nnoremap <C-h> :vertical resize -2<CR>
" nnoremap <C-l> :vertical resize +2<CR>

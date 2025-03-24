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
" set colorcolumn=+1"
set colorcolumn=
set hlsearch                            " highlight search results
set splitbelow                          " new panes appear more natural
set splitright
set background=dark
set signcolumn=yes
set laststatus=3                        " statusline for only active window

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
 
" enter: change word under cursor with one stroke
nnoremap <CR> ciw

" ctrl+s: classic Windows save keybind
noremap <C-s> :write<CR>

" In-editor make defaults
set makeprg=ips_build.sh\ -f

set errorformat=%f:%l:%c:%t:%m
set errorformat+=%f:%l:%c:%m
set errorformat+=%f:%l:%c
set errorformat+=%f:%s:%c
set errorformat+=%-G%.%#

" Variable to store the last make arguments
let g:last_make_args = ""

if has("nvim")
    command! -nargs=* Make let g:last_make_args = <q-args> | lua require('async_make').make(<q-args>)
else
    command! -nargs=* Make let g:last_make_args = <q-args> | make <q-args>
endif

" ctrl+alt+b: build program with last arguments
noremap <C-M-b> :execute 'Make' g:last_make_args<CR>



" TODO: it would be nice to save it to a tmp folder in case I accidentally close it.
" scratch buffer
command! Scratch new | setlocal bt=nofile bh=wipe nobl noswapfile nu | set wrap | setfiletype markdown

" messages
command! Messages new | setlocal bt=nofile bh=wipe nobl noswapfile nu | redir => messages_output | silent messages | redir END | put =messages_output | set ft=vim

" quickfix managment

" Position the (global) quickfix window at the very bottom of the window
" (useful for making sure that it appears underneath splits)
"
" NOTE: Using a check here to make sure that window-specific location-lists
" aren't effected, as they use the same `FileType` as quickfix-lists.
autocmd FileType qf if (getwininfo(win_getid())[0].loclist != 1) | wincmd J | endif

function! ToggleQuickfix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction

command! ClearQuickfixList cexpr []

noremap <leader>q :call ToggleQuickfix()<CR>
noremap <silent> <leader>Q :ClearQuickfixList<CR> \| :cclose<CR>

noremap [Q :cfirst<CR>
noremap ]Q :clast<CR>

" location list movement
noremap ]w :lnext<CR>
noremap [w :lprev<CR>

" disable ex mode
noremap Q <NOP>

" Move up/down lines visually when wrapped
nnoremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')
nnoremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')

" Leader+h clears search highlighting
map <silent> <Leader>h :noh<CR>

" Count occurrences of previous search
" https://vi.stackexchange.com/a/100
nnoremap <leader>C :%s///gn<CR>

" jump to next brace usually want the function to occupy most of screen
nnoremap ]] ]]zt
nnoremap [[ [[zt

" Close this buffer, but don't close the split or window
" noremap <leader>d :bprevious\|bdelete #<CR>
nnoremap <leader>d :bdelete<CR>

" tab management
nnoremap R :tabprevious<CR>
nnoremap T :tabnext<CR>
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>

" Zoom / Restore window.
function! s:ZoomToggle() abort
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <silent> <leader>z :ZoomToggle<CR>

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" window navigation
nnoremap <M-j> <C-W>j
nnoremap <M-k> <C-W>k
nnoremap <M-h> <C-W>h
nnoremap <M-l> <C-W>l


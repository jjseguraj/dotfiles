" Plugins
" ==========================================================================

" Find ctags file from current directory upwards until root
silent set tags=./tags;/

" Pathogen plugin runtimepath manager
execute pathogen#infect()
call pathogen#helptags() " generate helptags for everything in ‘runtimepath’
syntax on
filetype plugin indent on

" Tagbar
"   start on the left
"   find ctags.exe binary
let tagbar_left = 1
let g:tagbar_ctags_bin='ctags'

" Automatically set/unset Vim's paste mode
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"
inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction

" Look and feel
colorscheme slate
set number

if has('gui_running')
    set guifont=Roboto\ Mono\ Light\ for\ Powerline\ 11
"    set guifont=Inconsolata\ for\ Powerline:h15
"    set guifont=Courier_New:h11:cDEFAULT
endif

set termencoding=utf-8
set encoding=utf-8
let g:airline_powerline_fonts = 1
let g:airline_enable_branch = 1
set t_Co=256
set fillchars+=stl:\ ,stlnc:\
set term=xterm-256color

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
    let g:Powerline_symbols = 'fancy'
endif

" Open NERDTree + Tagbar + MiniBufExplorer
function! s:LayoutWindows()
    execute 'NERDTree'
    let nerdtree_buffer = bufnr(t:NERDTreeBufName)
    execute 'wincmd q'
    execute 'TagbarOpen'
    execute 'wincmd h'
    execute '35 wincmd |'
    execute 'split'
    execute 'b' . nerdtree_buffer
    execute ':1'
    execute 'wincmd j'
    execute ':1'

    let mbe_window = bufwinnr("-MiniBufExplorer-")
    if mbe_window != -1
        execute mbe_window . "wincmd w"
        execute 'wincmd K'
    endif
    execute 'resize +17'
    execute 'wincmd l'
endfunction

if has('gui_running')
    " NERDtree
    "   enabled by default
    "   close vim if the only remaining window is nerdtree
    autocmd vimenter * NERDTree
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
    autocmd VimEnter * call<SID>LayoutWindows()
endif

" Custom behavior
" ==========================================================================
" Space bar will remove the search highlight
nnoremap <space> :noh<return>

" Tab behaviour
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set fo+=j
set fo+=t
" set smartindent

" Enable folding and always start unfold
set foldmethod=syntax
au BufRead * normal zR

" Enable highlighting, incremental search and ignore case
set hls is ic

" Set the list of hidden chars to showed when ":set list" is entered
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<

" Disable line wrap and but not automatic insertion of newlines
set nowrap
set wrapmargin=0
set textwidth=78

" Enable mouse wheel
set mouse=a

" Mappings
" ==========================================================================
" CTags Key bindings
"   Alt-]   opens a list of all tag locations and allows choosing one
"   Ctrl-'  horizontal split to the tag location
"   Alt-'   vertical split to the tag location
"   Ctrl-\  open a new tab on the tag location
"map <A-]> g<C-]>
"map <C-'> <C-w><C-]>
"map <A-'> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
"map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>

" Custom plugins map to keys
" Toggle NERDTree and return to rhs pane
map <F12> <ESC>:NERDTreeToggle<RETURN><C-W><C-L>
map <F10> <ESC>:TagbarToggle<RETURN>

" Bindings to set and unset the limit bar
nnoremap <C-C>c :set cc=81 <CR> " For code edition
nnoremap <C-C>m :set cc=73 <CR> " For VCS message edition
nnoremap <C-C>r :set cc=0 <CR> " Remove the bar

" Leaves insert mode
inoremap ;; <Esc>

" Bindings useful for TDD 
""" These first two depend on the dev environment
" inoremap <C-O> <Esc>:up<CR>:make settime<CR>:!./settime<CR>
" nnoremap <C-O> :up<CR>:make settime<CR>:!./settime<CR>

""" Bindings to move between windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-L> <C-W><C-L>


" Leave insert mode
inoremap <C-[> <Esc>
" Leave insert mode and update the buffer
inoremap <C-O> <Esc>:up<CR>
" Leave insert mode, update the buffer and suspend
inoremap <C-S> <Esc>:up<CR>:sus<CR>
" Leave insert mode, update the buffer and quit
inoremap <C-X> <Esc>:up<CR>:q<CR>
" Leave insert mode and quit buffer without saving
inoremap <C-Q> <Esc>:q!<CR>
" Leave insert mode and quit all the buffers without saving
inoremap <C-A> <Esc>:qa!<CR>

" Update the buffer
nnoremap <C-O> :up<CR>
" Update the buffer and suspend
nnoremap <C-S> :up<CR>:sus<CR>
" Update the buffer and quit
nnoremap <C-X> :up<CR>:q<CR>
" Quit buffer without saving
nnoremap <C-Q> :q!<CR>
" Quit all the buffers without saving
nnoremap <C-A> :qa!<CR>
" ==========================================================================
" End of Mappings


let GtagsCscope_Auto_Load = 1
let GtagsCscope_Auto_Map = 1
let GtagsCscope_Quiet = 1
set cscopetag

" Autamic Deactivation of CapsLock
" Press C-^ to toggle Caps Lock
" Execute 'lnoremap x X' and 'lnoremap X x' for each letter a-z.
for c in range(char2nr('A'), char2nr('Z'))
  execute 'lnoremap ' . nr2char(c+32) . ' ' . nr2char(c)
  execute 'lnoremap ' . nr2char(c) . ' ' . nr2char(c+32)
endfor
" Kill the capslock when leaving insert mode.
autocmd InsertLeave * set iminsert=0

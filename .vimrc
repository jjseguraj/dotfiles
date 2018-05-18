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

" Look and feel
set number
set guifont=Roboto\ Mono\ Medium\ for\ Powerline\ 11
if has('gui_running')
    colorscheme slate
    set lines=999 columns=999
    let g:airline_powerline_fonts = 1
    let g:Powerline_symbols = 'fancy'
else
    colorscheme slate
    if exists("+lines")
        set lines=45
    endif
    if exists("+columns")
        set columns=90
    endif
endif

"if has('gui_running')
"endif

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
" set smartindent

" Enable folding and always start unfold
set foldmethod=syntax
au BufRead * normal zR

" Allows C-Q to reach Vim
silent !stty -ixon > /dev/null 2>&1

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
map <F12> <ESC>:NERDTreeToggle<RETURN>
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
"nnoremap <S-J> <C-W><C-J> " <S-J> joins the lower line at the end
nnoremap <S-K> <C-W><C-K> " Move to the minibuffer explorer
nnoremap <S-H> <C-W><C-H>
nnoremap <S-L> <C-W><C-L>


" Leave insert mode and update the buffer
inoremap <C-L> <Esc>:up<CR>
" Leave insert mode, update the buffer and quit
inoremap <C-K> <Esc>:up<CR>:q<CR>
" Leave insert mode and quit without saving
inoremap <C-Q> <Esc>:q!<CR>
" If in normal mode, update the buffer and suspend
nnoremap <C-L> :up<CR>:sus<CR>
" If in normal mode, update the buffer and quit
nnoremap <C-K> :up<CR>:q<CR>
" If in normal mode, quit without saving
nnoremap <C-Q> :q!<CR>
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

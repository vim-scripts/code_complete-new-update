"==================================================
" File:         code_complete.vim
" Brief:        function parameter complete, code snippets, and much more.
" Author:       Mingbai <mbbill AT gmail DOT com>, 
"               StarWing <weasley_wx AT qq DOT com>
"
" Last Change:  2008-11-06 18:38:25
" Version:      2.8
"
" How to use {{{
" Install:      1. Put code_complete.vim to plugin
"                  directory.
"               2. Use the command below to create tags
"                  file including signature field.
"                  ctags -R --c-kinds=+p --fields=+S .
"
" Usage:
"           hotkey:
"               "<A-S>" (default value of g:completekey)
"               we DON'T use <tab>, because it comflict with
"               superstab.vim, you will quickly find Alt-S will
"               be a good choice.
"               Do all the jobs with this key, see
"           example:
"               press <a-s> after function name and (
"                 foo ( <a-s>
"               becomes:
"                 foo ( `<first param>`,`<second param>` )
"               press <a-s> after code template
"                 if <a-s>
"               becomes:
"                 if( `<...>` )
"                 {
"                     `<...>`
"                 }
"
"
"           variables:
"
"               g:completekey
"                   the key used to complete function
"                   parameters and key words.
"
"               g:rs, g:re
"                   region start and stop
"               you can change them as you like.
"               after you change them, maybe you should update 
"               your template file, you can use this command:
"               :ResetTemplate<CR>
"
"               g:user_defined_snippets
"                   file name of user defined snippets.
"                   now it named my_snippets.template, use this
"               postfix to prevent Vim load it automatically
"
"           key words:
"               see "my_snippets.template" file.
" }}}
"==================================================
" must after Vim 7.0 and check whether it has loaded {{{
if v:version < 700 || exists('g:loaded_code_complete')
    finish
endif
let g:loaded_code_complete = 1
" }}}
" Variable Definations {{{1
" options, define them as you like in vimrc:

" hotkey, didn't use <tab>, for compatible with supertab.vim
if !exists("g:completekey")
    let g:completekey = "<a-d>"
endif

" the complete dictionary, we fill it in my_snippets.template later
if !exists("g:template")
    let g:template = {}
endif

if !exists("g:rs")
    let g:rs = '`<'    " region start
endif

if !exists("g:re")
    let g:re = '>`'    " region stop
endif

" define the default template file
" you can use ResetTemplate to update it.
if !exists("g:user_defined_snippets")
    let g:user_defined_snippets = "plugin/my_snippets.template"
endif

" ----------------------------
" inner variable, control the action of function SwitchRegion()
" -1 means don't jump to anywhere, and -2 means do nothing
let s:jumppos = -1

" Function Definations {{{1

function! CodeCompleteStart()
    exec "inoremap <silent><buffer> ".g:completekey.
                \ " <c-r>=CodeComplete()<cr>".
                \ "<c-r>=SwitchRegion()<cr>"
    exec 'snoremap <silent><buffer> '.g:completekey.
                \ " <esc>:exec 'norm '.SwitchRegion()<cr>"
endfunction

function! CodeCompleteStop()
    exec "silent! iunmap <buffer> ".g:completekey
    exec "silent! sunmap <buffer> ".g:completekey
endfunction

function! FunctionComplete(fun)
    let signature_list = []
    let signature_word = {}
    let ftags = taglist('^'.a:fun.'$')

    " if can't find the function
    if type(ftags) == type(0) || empty(ftags)
        return ''
    endif

    for item in ftags
        " item must have keys kind, name and signature, and must be the
        " type of p(declare) or f(defination), function name must be same
        " with a:fun, and must have param-list
        " if any reason can't satisfy, to next iteration
        if !has_key(item, 'kind') || !has_key(item, 'name') 
                    \ || !has_key(item, 'signature')
                    \ || (item.kind != 'p' && item.kind != 'f')
                    \ || item.name != a:fun
                    \ || match(item.signature, '(\s*\%(void\)\=\s*)') >= 0
            continue
        endif

        let tmp = substitute(item.signature, ',\s*', g:re.', '.g:rs, 'g')
        let tmp = substitute(tmp, '(\s*\(.*\)\s*)',
                    \ g:rs.'\1'.g:re.')', 'g')
        
        if !has_key(signature_word, tmp)
            let signature_word[tmp] = 0
            let s:signature_list += [{'word': tmp, 'menu': item.filename}]
        endif
    endfor

    " can't find the argument-list, means it's a void function
    if signature_list==[]
        return ')'
    endif

    " only one list find, that is we need!
    if len(signature_list) == 1
        return signature_list[0]['word']
    else
        " make a complete menu
        call complete(col('.'), signature_list)
        " tell SwitchRegion do nothing
        let s:jumppos = -2
        return ''
    endif
endfunction

function! TemplateComplete(cword)
    if has_key(g:template,&ft)
        let result = get(g:template[&ft], a:cword, '')
    else
        let result = get(g:template['_'], a:cword, '')
    endif
    return result
endfunction

function! SwitchRegion()
    " sometimes we don't do anything...
    if s:jumppos == -2
        let s:jumppos = -1
        return ''
    endif
    let c_pos = getpos('.')

    " if call Complete function once, set cursor to that line.
    if s:jumppos != -1
        call cursor(s:jumppos, 1)
        let s:jumppos = -1
    endif

    " return empty string when can't find the token IN SCREEN
    let token = g:rs.'.\{-}'.g:re
       if search(token, '', line('w$')) == 0
        call cursor(line('w0'), 1)
        if search(token, '', c_pos[1]) == 0
            call setpos('.', c_pos)
            return ''
        endif
    endif

    call search(g:rs, 'c')
    normal v
    call search(g:re,'e',line('.'))
    if &selection == "exclusive"
        exec "norm " . "\<right>"
    endif
    return "\<c-\>\<c-n>gvo\<c-g>"
endfunction

function! CodeComplete()
    " get the template name of function name
    let plist = matchlist(getline('.')[:col('.') - 2], '\(\w*\)\s*\((\)\=\s*$')
    
    if plist[2] == '(' " it's a function, so...
        let result = FunctionComplete(plist[1])

        " when the function doesn't have any argument,
        " tell SwitchRegion, don't do anything
        if result == ')'
            let s:jumppos = -2
            return ')'
        endif
    else " or, it must be a template item
        let result = TemplateComplete(plist[1])
        " if we find a answer, delete the template name itself
        if result != ''
            let result = "\<c-w>".result
        endif
    endif

    " if find anything, tell SwitchRegion jump to that line.
    let s:jumppos = empty(result) ? -1 : line('.')
    " if the completekey is tab, we must add a tab when find nothing
    return result == '' && g:completekey ==? "<tab>" ? "\<tab>" : result
endfunction

" [Get converted file name like __THIS_FILE__ ]
function! GetFileName()
    let filename = toupper(expand('%:t'))
    let name = substitute(filename,'\.','_',"g")
    let name = "__".name."__"
    return name
endfunction

" Commands, Autocommands and Menu defined {{{1
autocmd BufReadPost,BufNewFile * call CodeCompleteStart()

" you can input the command with Start<Tab>, it can be completed.
command StartCodeComplele call CodeCompleteStart()
command StopCodeComplete call CodeCompleteStop()
command ResetTemplate exec "silent! runtime ".g:user_defined_snippets

" Menus:
menu <silent> &Tools.Code\ Complete\ Start    :call CodeCompleteStart()<CR>
menu <silent> &Tools.Code\ Complete\ Stop     :call CodeCompleteStop()<CR>
" }}}
" Some Initialization works {{{
"
" Load template settings
ResetTemplate

" ensure the start function must be called when start vim
StartCodeComplele

" }}}
" vim: ft=vim:ff=unix:fdm=marker:ts=4:sw=4:et

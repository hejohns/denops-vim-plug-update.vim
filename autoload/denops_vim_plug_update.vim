scriptencoding utf8

function s:PlugUpdate_success(v) abort
    " NOTE: 2025-02-01: even though we should probably restart vim in general,
    " I usually don't run into huge issues and having to reopen vim is really
    " annoying
    echomsg '[denops-vim-plug-update] ' .. a:v .. " plugins updated" .. (a:v ? ". Please restart Vim to reload newly updated plugins if anything weird happens" : "")
endfunction

function s:PlugUpdate_failure(e) abort
    echoerr "[denops-vim-plug-update] plugin update failed for some reason. See echoerr log, and try `call denops_vim_plug_update#init()` again"
    call hejohns#PlugUpdate()
endfunction

function denops_vim_plug_update#init() abort
    if !exists('g:plugs')
        echoerr("[denops-vim-plug-update] `g:plugs` doesn't exist-- it's supposed to be defined by vim-plug, by `plug#end()`")
    endif
    let l:plugs = deepcopy(g:plugs)
    for key in keys(g:plugs)
        " vim-plug's 'do' field can contain a lambda/funcref
        " (eg `Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }`)
        " so remove them, or else json_encode fails
        if has_key(l:plugs[key], 'do')
            call remove(l:plugs[key], 'do')
        endif
    endfor
    call denops#request_async('denops-vim-plug-update', 'PlugUpdate', [json_encode(l:plugs)], {v -> s:PlugUpdate_success(v)}, {e -> s:PlugUpdate_failure(e)})
endfunction

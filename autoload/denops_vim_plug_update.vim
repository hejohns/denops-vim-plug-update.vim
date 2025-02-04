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
        echoerr "[denops-vim-plug-update] `g:plugs` doesn't exist-- it's supposed to be defined by vim-plug, by `plug#end()`"
    endif
    " we could just have denops operate on `g:plugs` directly, but let's try
    " to minimize the amount of work the vim process has to do itself
    let l:plugs = deepcopy(g:plugs)
    let g:denops_vim_plug_update#post_update_hooks = {}
    for plugin in keys(g:plugs)
        " vim-plug's 'do' post-update hook can either contain a string
        " (:Ex command or system command) or a lambda/funcref
        " (eg `Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }`)
        " but json_encode() errors on a funcref
        "
        " SEE: https://github.com/junegunn/vim-plug/tree/a7d4a73dd682f0c192b3003efcf86e0dab41602c?tab=readme-ov-file#post-update-hooks
        if has_key(l:plugs[plugin], 'do')
            if type(l:plugs[plugin]['do']) == v:t_string
                " pass it along to denops
                " (either an :Ex or system command)
            elseif type(l:plugs[plugin]['do']) == v:t_func
                let g:denops_vim_plug_update#post_update_hooks[plugin] = l:plugs[plugin]['do']
                " TODO: vim-plug also allows functions that take a dictionary
                " argument (https://github.com/junegunn/vim-plug/tree/a7d4a73dd682f0c192b3003efcf86e0dab41602c?tab=readme-ov-file#post-update-hooks)
                let l:plugs[plugin]['do'] = ":call g:denops_vim_plug_update#post_update_hooks['" .. plugin .. "']()"
            else
                echoerr "[denops-vim-plug-update] vim-plug 'do' post-update hook for '" .. plugin .. "' is neither a string nor a funcref"
                call remove(l:plugs[plugin], 'do')
            endif
        endif
    endfor
    call denops#request_async('denops-vim-plug-update', 'PlugUpdate', [json_encode(l:plugs)], {v -> s:PlugUpdate_success(v)}, {e -> s:PlugUpdate_failure(e)})
endfunction

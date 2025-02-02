if exists('g:loaded_denops_vim_plug_update') || &compatible
    finish
else
    let g:loaded_denops_vim_plug_update = v:true
endif

autocmd User DenopsReady call denops#plugin#wait_async('denops-vim-plug-update', function('denops_vim_plug_update#init'))

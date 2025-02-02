## NAME

denops-vim-plug-update.vim - denops vim plugin to asynchronously update plugins managed by vim-plug

## INSTALLATION

Install with your choice of plugin manager, eg with vim-plug:

    Plug 'https://github.com/hejohns/denops-vim-plug-update.vim'

## DESCRIPTION

After vim startup, this small denops plugin checks for new commits to any
installed plugins managed by vim-plug.
This is essentially a wrapper around `git fetch --all`, `git status`, `git pull`.
If any plugins are updated, a `:echomsg` warning will remind the user to
restart vim if any issues are encountered.
(It seems possible if a plugin has autoloaded functions, that before vim has a chance to source the autoload/ file,
 a plugin update modifies the autoload/ function in a way incompatible with the already-sourced plugin/ .
 Although this seems to already be the case with `:PlugUpdate`.)

Missing plugins are *not* currently handled.
See [the vim-plug extras page](https://github.com/junegunn/vim-plug/wiki/extra#automatically-install-missing-plugins-on-startup)
for a way to automatically install missing plugins.
Note that the above vimscript blocks the editor while installing the missing
plugins for the first time.
This seems like a reasonable thing to do for missing plugins.

## SEE ALSO

- [denops](https://github.com/vim-denops/denops.vim)
- [vim-plug](https://github.com/junegunn/vim-plug)

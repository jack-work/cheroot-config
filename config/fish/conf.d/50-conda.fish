# Lazy conda. Sourcing conda's hook eagerly costs ~200ms and pollutes PATH on
# every shell; instead `conda` is a stub that loads the real thing on first use
# and then re-dispatches.
#
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
function load_conda
    if test -f /opt/miniconda3/bin/conda
        eval /opt/miniconda3/bin/conda "shell.fish" hook $argv | source
    else if test -f /opt/miniconda3/etc/fish/conf.d/conda.fish
        source /opt/miniconda3/etc/fish/conf.d/conda.fish
    else
        set -gx PATH /opt/miniconda3/bin $PATH
    end
end
# <<< conda initialize <<<

function conda --description 'lazy-load miniconda on first use'
    functions --erase conda
    load_conda
    conda $argv
end

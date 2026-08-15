# Lazy conda. Sourcing conda's hook eagerly costs ~200ms and pollutes PATH on
# every shell; instead `conda` is a stub that loads the real thing on first use
# and then re-dispatches.
#
# Mirrors config/fish/conf.d/50-conda.fish.

load_conda() {
    unalias conda 2>/dev/null
    unset -f conda 2>/dev/null

    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f /opt/miniconda3/etc/profile.d/conda.sh ]; then
        . /opt/miniconda3/etc/profile.d/conda.sh
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
    unset __conda_setup
    unset -f load_conda
}

if [ -d /opt/miniconda3 ]; then
    conda() {
        load_conda
        conda "$@"
    }
fi

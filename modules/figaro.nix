# figaro — ONE feature, BOTH shells, in one file.
#
# This aspect is the reason the dendritic refactor pays for itself. figaro
# touches four places across two shells:
#
#   fish  conf.d/65-figaro-prompt.fish   +  completions/{figaro,fig}.fish
#   bash  .bashrc.d/65-figaro-prompt.sh  +  bash-completion/completions/{figaro,fig}
#
# Under the previous layout those four would have been scattered across
# home.nix and two config trees, and the single most important fact about them —
# that the fish and bash prompt hooks MUST differ, because bash loses figaro's
# parent-pid binding to any redirect or pipe while fish does not — would have
# lived in a comment nobody reads. Here the two files sit side by side and the
# asymmetry is the first thing you see.
#
# Aliases (fig/q/qe/qf/l/x) are NOT here: they are plain shell aliases with no
# figaro-specific machinery, so they live with the other shared aliases in
# shell/core.nix and are rendered into both shells from one attrset.
{
  flake.modules.homeManager.figaro = {
    xdg.configFile = {
      # fish forks each pipeline member itself, so a pipe AND a redirect both
      # keep fish as figaro's parent. The binding survives.
      "fish/conf.d/65-figaro-prompt.fish".source = ../config/figaro/prompt.fish;

      "fish/completions/figaro.fish".source = ../config/figaro/completions/figaro.fish;
      "fish/completions/fig.fish".source = ../config/figaro/completions/fig.fish;
    };

    home.file = {
      # bash does NOT. Any redirect or pipe forks a subshell and figaro reports
      # "no figaro bound to this shell" forever, silently. Read the header of
      # this file before editing it.
      ".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;

      # bash-completion autoloads from here on first Tab. Requires
      # /usr/share/bash-completion/bash_completion to have been sourced —
      # shell/bash.nix does that.
      ".local/share/bash-completion/completions/figaro".source = ../config/figaro/completions/figaro.bash;
      ".local/share/bash-completion/completions/fig".source = ../config/figaro/completions/fig.bash;
    };
  };
}

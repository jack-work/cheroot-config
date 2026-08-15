# git — the tool AND its configuration.
#
# WHY THIS IS ITS OWN ASPECT. Until now ~/.gitconfig was hand-written and
# unmanaged, and it carried a latent trap:
#
#     helper = !/usr/bin/gh auth git-credential
#
# an ABSOLUTE path into pacman's github-cli. The moment that package is removed
# in favour of nix's `gh` — which docs/pacman-audit.md recommends — git
# authentication to github.com and gist.github.com breaks, with an error that
# points at git rather than at the package you removed. Declaring the helper
# UNQUALIFIED fixes it permanently: `gh` resolves through PATH, so it works
# whether the binary came from pacman, nix, or a different host entirely.
#
# ---------------------------------------------------------------------------
# YOU MUST DELETE ~/.gitconfig BY HAND AFTER THE FIRST SWITCH
# ---------------------------------------------------------------------------
# home-manager writes git config to $XDG_CONFIG_HOME/git/config, NOT to
# ~/.gitconfig. git reads BOTH ("if both files exist, both files are read", in
# that order) and the LAST value read wins. So a surviving hand-written
# ~/.gitconfig silently overrides everything here.
#
# `home-manager switch -b bak` will NOT save you: it only backs up paths it
# manages, and ~/.gitconfig is not one of them. It is left untouched and keeps
# winning.
#
# Measured with both files present:
#
#     git config --get credential."https://github.com".helper
#     -> !/usr/bin/gh auth git-credential      # the STALE one
#
# and with ~/.gitconfig removed:
#
#     -> !gh auth git-credential               # correct
#
# So, once, after switching:
#
#     mv ~/.gitconfig ~/.gitconfig.pre-nix
#
# ---------------------------------------------------------------------------
# NOTE ON `package = null`: many home-manager program modules declare their
# package option `nullable`, which lets you take the CONFIGURATION MANAGEMENT
# while leaving the binary to the distro — the natural split on Arch. Verified
# available for git, go, btop, less, ripgrep, fastfetch, bun, uv, npm, micro,
# aichat, lazygit and tmux. It is NOT used here: git is small, pure, identical
# in version (2.55.0 both sides), and having it in the flake means every host
# gets it. The option is documented because it is the right answer for anything
# heavier.
{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "gluck";
          email = "gluck@kelliher.info";
        };

        init.defaultBranch = "master";

        # The empty first element clears any helper inherited from
        # /etc/gitconfig before appending ours — the same two-line shape the
        # hand-written file had, preserved deliberately.
        credential."https://github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
        credential."https://gist.github.com".helper = [
          ""
          "!gh auth git-credential"
        ];
      };
    };

    # delta was already installed as a loose package; wiring it through git's
    # own integration is what actually makes it the pager.
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
  };
}

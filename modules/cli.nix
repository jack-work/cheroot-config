# Interactive command-line tooling.
#
# Every integration below enables BOTH shells from a single `enable`, which is
# most of what "share the same nix props between fish and bash" means in
# practice. The one exception is fzf's fish integration, switched off in
# shell/fish.nix because the vendored fzf.fish plugin already owns those keys.
#
# ---------------------------------------------------------------------------
# PACMAN PACKAGES THAT MUST BE REMOVED BEFORE THE FIRST SWITCH
# ---------------------------------------------------------------------------
# ~/.nix-profile/bin precedes /usr/bin, so anything listed here that ALSO exists
# in pacman is shadowed rather than replaced: two copies on disk, the nix one
# winning silently, and pacman upgrades that appear to do nothing.
#
#     sudo pacman -Rns github-cli lazygit fzf
#
#   github-cli  superseded by `gh` below (nix 2.96.0 vs pacman 2.97.0)
#   lazygit     REPLACED BY gitui at your request -- see the warning below
#   fzf         superseded by nix's. Verified safe: the generated .bashrc calls
#               `<nix fzf>/bin/fzf --bash` directly rather than sourcing
#               /usr/share/fzf/*, and nix's fzf ships fzf-tmux, which
#               tmux.conf's `prefix + B` bookmark picker needs.
#
#               ONE CAVEAT: tmux `run-shell` inherits the tmux SERVER's
#               environment, which was captured when the server started. A
#               server predating the switch will not have ~/.nix-profile/bin on
#               PATH and `fzf-tmux` will not resolve. `tmux kill-server` (or a
#               reboot) once after switching fixes it permanently.
#
# ---------------------------------------------------------------------------
# WARNING: REMOVING lazygit BREAKS THREE NEOVIM BINDINGS
# ---------------------------------------------------------------------------
# lazygit is not a standalone tool here; the nvim config drives it:
#
#   ~/.config/nvim/lua/plugins/snacks.lua   <leader>gg / <leader>gl / <leader>gf
#                                           (Snacks.lazygit, log, log_file)
#   ~/.config/nvim/lua/plugins/tree-bear.lua  require("tree-bear").lazygit_worktree()
#
# gitui is NOT a drop-in: snacks.nvim has no gitui provider, and tree-bear's
# worktree helper shells out to lazygit by name. Those bindings will error until
# the nvim config is updated. Nothing here can fix that -- ~/.config/nvim is
# deliberately not managed by this flake (lazy.nvim and mason write into it).
{
  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ripgrep
        fd
        jq
        eza
        bat
        delta
        gitui
        yazi
        tree
        git
        gh
      ];

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        # enableFishIntegration is forced off in shell/fish.nix.
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };
    };
}

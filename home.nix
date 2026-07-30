{ config, pkgs, lib, ... }:

let
  home = config.home.homeDirectory;

  # Substitute @HOME@ in verbatim config files that need absolute paths.
  subHome = path:
    builtins.replaceStrings [ "@HOME@" ] [ home ] (builtins.readFile path);
in
{
  #============================================================================
  # OPTIONS — host modules use these to vary machine-specific behaviour.
  #============================================================================
  options.my = {
    niriExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Host-specific niri KDL appended verbatim to the machine-agnostic base.
        Use for output blocks (scale, position) that only make sense on one box.
      '';
    };

    waybarModulesRight = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "custom/weather" "custom/wifi" "custom/storage" "memory" "cpu" "wireplumber" ];
      description = ''
        Right-hand waybar modules. Laptops add "battery" and "backlight";
        desktops leave them out. The base config DEFINES both modules but does
        not display them, so this is the only knob needed.
      '';
    };
  };

  config = {
    home.stateVersion = "26.11";

    #==========================================================================
    # PACKAGES — user-space only.
    #
    # Anything touching the GPU, display stack, hardware, or a system systemd
    # unit comes from pacman instead. nixpkgs OpenGL on non-NixOS is
    # nixpkgs#9415 (open since 2015): a nix-built compositor or GPU-accelerated
    # terminal links nixpkgs Mesa against the Arch kernel driver and renders in
    # software, or not at all.
    #
    # pacman owns: niri, waybar, mako, alacritty, swaybg/idle/lock, browsers,
    #              fish (login shell needs /etc/shells + a stable path).
    # nix owns:    everything below.
    #==========================================================================
    home.packages = with pkgs; [
      neovim
      tmux

      fzf
      ripgrep
      fd
      zoxide
      starship
      jq
      eza
      bat
      delta
      lazygit
      yazi
      tree

      # nvim build deps: treesitter compiles parsers, mason fetches LSPs.
      # mason's prebuilt binaries work here because Arch is FHS — they need
      # /lib64/ld-linux, which exists on Arch and would NOT on NixOS.
      gcc
      gnumake
      tree-sitter
      nodejs
      python3

      git
      gh

      # Formatters used by conform.nvim (formatters_by_ft in lua/plugins/conform.lua).
      # Without these, :w on a markdown/lua/python file reports "no formatters".
      mdformat        # markdown
      stylua          # lua
      black           # python
      sql-formatter   # sql

      (pkgs.callPackage ./pkgs/mako-term.nix { })
    ];

    programs.home-manager.enable = true;

    #==========================================================================
    # CONFIGS
    #
    # MUTABILITY RULE: anything that writes into its own config directory
    # cannot be a /nix/store symlink (store paths are read-only). That rules out
    #   ~/.config/nvim         — lazy.nvim + mason write there  → git clone
    #   ~/.config/tmux/plugins — tpm clones there               → conf only
    # Everything else is safe to manage declaratively.
    #==========================================================================
    xdg.configFile = {
      "niri/config.kdl".text =
        subHome ./config/niri/config.kdl + config.my.niriExtra;

      # rofi — the picker, with the Kanagawa theme carried over from spain.
      # NOTE: rofi comes from pacman (it is a Wayland client that draws), only
      # its configuration is managed here.
      "rofi/config.rasi".source = ./config/rofi/config.rasi;
      "rofi/kanagawa.rasi".source = ./config/rofi/kanagawa.rasi;

      "mako/config".source = ./config/mako/config;
      "alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;

      "waybar/style.css".source = ./config/waybar/style.css;
      "waybar/modules".source = ./config/waybar/modules;
      "waybar/config".text =
        # A single unambiguous @MODULES_RIGHT@ placeholder, NOT a multi-line match.
        # Nix '' strings strip common leading indentation, so matching a
        # pretty-printed JSON block silently fails and replaceStrings no-ops.
        builtins.replaceStrings
          [ "@MODULES_RIGHT@" ]
          [ (lib.concatMapStringsSep ", " (m: "\"${m}\"") config.my.waybarModulesRight) ]
          (builtins.readFile ./config/waybar/config-niri);

      # fish — fisher deliberately dropped; nix provides fzf/zoxide/starship
      # integrations instead (see programs.* below).
      "fish/config.fish".source = ./config/fish/config.fish;
      "fish/conf.d".source = ./config/fish/conf.d;
      "fish/functions".source = ./config/fish/functions;
      "fish/themes".source = ./config/fish/themes;

      # tmux: ONLY the conf file. plugins/ stays mutable for tpm.
      "tmux/tmux.conf".source = ./config/tmux/tmux.conf;
    };

    home.file.".config/mako/mako-term.sh" = {
      source = ./config/mako/mako-term.sh;
      executable = true;
    };

    home.file.".local/share/wallpaper/wallpaper.jpg".source = ./wallpaper.jpg;

    #==========================================================================
    # SHELL INTEGRATION — replaces the dropped fisher plugins
    #==========================================================================
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    #==========================================================================
    # ACTIVATION — mutable-state bootstrap
    #==========================================================================
    home.activation = {
      cloneNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d "${home}/.config/nvim/.git" ]; then
          run ${pkgs.git}/bin/git clone \
            https://github.com/jack-work/nvim-gluck "${home}/.config/nvim"
        else
          echo "nvim config already a git repo; leaving it alone"
        fi
      '';

      cloneTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d "${home}/.config/tmux/plugins/tpm" ]; then
          run ${pkgs.git}/bin/git clone \
            https://github.com/tmux-plugins/tpm "${home}/.config/tmux/plugins/tpm"
        fi
      '';

      # Validate the KDL we just wrote. Catching a bad config here beats
      # discovering it at the greeter with no way back in.
      validateNiri = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if command -v niri >/dev/null 2>&1; then
          if niri validate -c "${home}/.config/niri/config.kdl" >/dev/null 2>&1; then
            echo "niri config: VALID"
          else
            echo "WARNING: niri config FAILED validation:"
            niri validate -c "${home}/.config/niri/config.kdl" 2>&1 | head -20 || true
          fi
        fi
      '';
    };
  };
}

{
  description = "gluck / cheroot — dendritic home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Every .nix file under ./modules becomes a flake-parts module, imported
    # automatically. This is what makes file paths non-structural: move and
    # rename freely, nothing references them.
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen. Not in nixpkgs at all, so the browser's home-manager module comes
    # from the community flake — it is home-manager's own mkFirefoxModule
    # pointed at Zen's paths, plus Zen-only machinery (keyboard shortcuts,
    # mods, spaces). See modules/desktop/zen.nix; on both Arch hosts we take
    # the MODULE and leave the BINARY to pacman.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Signed add-on xpis, generated from AMO. The one add-on this set lacks is
    # pinned by hand in pkgs/firefox-xpi.nix.
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # figaro, for hosts that CONSUME it rather than build it.
    #
    # Deliberately not used by gluck — see modules/figaro.nix and
    # modules/hosts/gluck.nix. The machine where figaro is developed takes its
    # binary from its own dev loop; every other machine takes this pin.
    figaro = {
      url = "github:jack-work/figaro";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The whole flake is one import-tree call. Nothing else belongs in this file —
  # add a module under ./modules instead.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

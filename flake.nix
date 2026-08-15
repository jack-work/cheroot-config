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
  };

  # The whole flake is one import-tree call. Nothing else belongs in this file —
  # add a module under ./modules instead.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

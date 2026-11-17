{
  description = "nixos-system-charter: shared concern-sliced NixOS and Home Manager aspects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    figaro = {
      url = "github:jack-work/figaro/v0.71.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hush = {
      url = "github:jack-work/hush/v0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lockGate = import ./lib/lock-gate.nix { inherit (inputs.nixpkgs) lib; };
    in
    assert lockGate.assertGithubOnlyLock (builtins.fromJSON (builtins.readFile ./flake.lock));
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

{
  description = "Desktop system flake (gluck, cheroot, merlin) consuming nixos-system-charter";

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
      url = "github:jack-work/figaro/v0.76.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    merlin-figaro = {
      url = "github:jack-work/figaro/v0.72.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hush = {
      url = "github:jack-work/hush/v0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    charter = {
      url = "github:jack-work/cheroot-config/e286d0593f0789285e8a73c0161ab6f73370f206?dir=charter";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-parts.follows = "flake-parts";
      inputs.import-tree.follows = "import-tree";
      inputs.figaro.follows = "figaro";
      inputs.hush.follows = "hush";
    };

    cerrojo = {
      url = "github:jack-work/cerrojo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rou2 = {
      url = "git+ssh://git@spain/var/lib/keel/jack/rou2.git?ref=refs/heads/feat/anthropic-max&rev=aac52f7d0b71afd164ce434d13ada67004ccfcf0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    keel = {
      url = "git+ssh://git@spain/jack/keel.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    captains-log = {
      url = "git+ssh://git@spain/jack/captains-log.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

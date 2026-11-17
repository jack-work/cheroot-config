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
      url = "github:jack-work/figaro/v0.71.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    merlin-figaro = {
      url = "github:jack-work/figaro/180d4906346f73c403c2daa8cea299f30c75ed53";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hush = {
      url = "github:jack-work/hush/v0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    charter = {
      url = "github:jack-work/cheroot-config/144aba3b0d5e0c9a9152b44e2ddaa8b17a88fc2a?dir=charter";
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
      flake = false;
    };

    captains-log = {
      url = "git+ssh://git@spain/jack/captains-log.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

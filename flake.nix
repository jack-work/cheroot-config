{
  description = "cheroot / spain — portable home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = hostModule: username:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            hostModule
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            }
          ];
        };
    in
    {
      packages.${system} = {
        mako-term = pkgs.callPackage ./pkgs/mako-term.nix { };
        default = self.packages.${system}.mako-term;
      };

      homeConfigurations = {
        "marlowe@cheroot" = mkHome ./hosts/cheroot.nix "marlowe";
        # desktop, added later:
        # "gluck@spain" = mkHome ./hosts/spain.nix "gluck";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ home-manager nixfmt-rfc-style shellcheck ];
      };
    };
}

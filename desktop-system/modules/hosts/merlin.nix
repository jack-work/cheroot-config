{ inputs, config, ... }:
let
  aspects = config.flake.lib;
  homeAspects = builtins.filter (name: name != "hush") aspects.coreAspects ++ aspects.guiAspects;

  merlinHome =
    { pkgs, ... }:
    {
      imports = map (name: config.flake.modules.homeManager.${name}) (
        homeAspects
        ++ [
          "desktop"
          "commander"
          "school-tools"
        ]
      );
      home = {
        username = "jack";
        homeDirectory = "/home/jack";
        packages = with pkgs; [
          xwayland-satellite
          wl-clipboard
          playerctl
          pavucontrol
          wiremix
          grim
          slurp
          swappy
          nemo
          gnome-calculator
          xdg-utils
          libsForQt5.qt5ct
        ];
      };
      my = {
        platform = {
          desktopFromNix = true;
          toolchainFromNix = true;
          mediaFromNix = true;
        };
        figaro.package = null;
        commander = {
          instance = "merlin";
          package = inputs.merlin-figaro.packages.${pkgs.stdenv.hostPlatform.system}.figaro;
          bootstrapDoc = "docs/migration/merlin-bootstrap.md";
          skills.merlin-setup = ../../config/figaro/merlin-setup.md;
        };
        niri.extra = ''
          output "Dell Inc. DELL U2719D DDZQJS2" {
              mode "2560x1440@59.951"
              position x=0 y=0
          }
          output "Lenovo Group Limited LEN P27h-10 0x58314841" {
              mode "2560x1440@59.951"
              position x=0 y=1440
          }
        '';
      };
      systemd.user.services.polkit-agent = {
        Unit = {
          Description = "Desktop authorization agent";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };

  systemBase = config.flake.modules.nixos.system-base;
in
{
  flake.modules.homeManager.merlin = merlinHome;
  flake.homeConfigurations = aspects.mkHost {
    user = "jack";
    host = "merlin";
    aspects = [ "merlin" ];
  };

  flake.nixosModules.merlin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.merlin-figaro.nixosModules.default
        systemBase
      ];
      networking = {
        hostName = "merlin";
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
        };
        firewall.enable = true;
      };
      time.timeZone = "America/New_York";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nixpkgs.config.allowUnfree = true;
      users.users.jack = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/jack";
        group = "jack";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.fish;
      };
      users.groups.jack.gid = 1000;
      programs.fish.enable = true;
      programs.niri.enable = true;
      programs.niri.package = pkgs.niri;
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd ${pkgs.niri}/bin/niri-session";
          user = "greeter";
        };
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        graphics.enable = true;
        nvidia = {
          modesetting.enable = true;
          open = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
        };
      };
      security.polkit.enable = true;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
      environment.systemPackages = with pkgs; [
        curl
        iwd
        alsa-utils
        pulseaudio
      ];
      services.figaro.enable = lib.mkForce false;
      systemd.services.systemd-hibernate.enable = false;
      systemd.services.systemd-hybrid-sleep.enable = false;
      systemd.services.systemd-suspend-then-hibernate.enable = false;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.jack = merlinHome;
      };
      system.stateVersion = "26.11";
    };
}

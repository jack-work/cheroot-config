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
          skills = {
            merlin-setup = ../../config/figaro/merlin-setup.md;
            merlin-context = ../../config/figaro/merlin-context.md;
          };
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

  flake.nixosConfigurations.merlin = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.merlin
      ../../hosts/merlin/hardware-configuration.nix
      ../../hosts/merlin/boot.nix
    ];
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
        useDHCP = false;
        useNetworkd = true;
        wireless.iwd = {
          enable = true;
          settings = {
            General = {
              EnableNetworkConfiguration = true;
              "Disable2.4GHz" = true;
            };
            Network.NameResolvingService = "systemd";
          };
        };
        firewall.enable = true;
      };
      systemd.network = {
        enable = true;
        networks."20-wired" = {
          matchConfig.Driver = "r8169";
          networkConfig.DHCP = "yes";
        };
        wait-online.enable = false;
      };
      services.resolved.enable = true;
      boot.blacklistedKernelModules = [
        "iwlwifi"
        "iwlmvm"
      ];
      boot.extraModprobeConfig = "options mt7921e disable_aspm=1";
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
        extraGroups = [ "wheel" ];
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
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        nvidia = {
          modesetting.enable = true;
          open = true;
          powerManagement.enable = true;
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
      };
      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
        builtins.toJSON {
          rules = [
            {
              pattern = {
                feature = "procname";
                matches = "niri";
              };
              profile = "Limit Free Buffer Pool On Wayland Compositors";
            }
          ];
          profiles = [
            {
              name = "Limit Free Buffer Pool On Wayland Compositors";
              settings = [
                {
                  key = "GLVidHeapReuseRatio";
                  value = 0;
                }
              ];
            }
          ];
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
        (writeShellApplication {
          name = "merlin-diag";
          runtimeInputs = [
            coreutils
            gnugrep
            iproute2
            kmod
            util-linux
            systemd
            iwd
          ];
          text = ''
            set +e
            out=/boot/merlin-diag-$(date +%s).txt
            section() {
              printf '\n===== %s\n' "$1"
              shift
              "$@" 2>&1
            }
            {
              section "uname -a" uname -a
              section "nvidia-smi" ${lib.getExe' config.hardware.nvidia.package.bin "nvidia-smi"}
              section "lsmod" sh -c "lsmod | grep -E 'nvidia|nouveau|mt79|iwl|r8169'"
              section "ip -br addr" ip -br addr
              section "ip route" ip route
              section "resolvectl status" resolvectl status
              section "iwctl station list" iwctl station list
              section "networkctl list" networkctl list
              section "rfkill" rfkill
              section "journal warnings" sh -c "journalctl -b -p warning --no-pager | tail -400"
              section "greetd" sh -c "journalctl -b -u greetd --no-pager | tail -100"
              section "uid 1000 graphics" sh -c "journalctl -b _UID=1000 --no-pager | grep -iE 'niri|egl|gbm|drm|nvidia' | tail -200"
              section "/dev/dri" ls -l /dev/dri
              section "/proc/cmdline" cat /proc/cmdline
            } > "$out"
            echo "$out"
          '';
        })
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

let
  flake = builtins.getFlake "path:${toString ../.}";
  lib = flake.inputs.nixpkgs.lib;
  hm = flake.homeConfigurations."jack@merlin".config;
  system =
    (flake.inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ flake.nixosModules.merlin ];
    }).config;
  integrated = system.home-manager.users.jack;
  host = flake.nixosConfigurations.merlin.config;
  hostFailedAssertions = map (entry: entry.message) (
    builtins.filter (entry: !entry.assertion) host.assertions
  );
  btrfsMounts = [
    "/"
    "/home"
    "/nix"
    "/var/log"
  ];
  unit = integrated.systemd.user.services.figaro-commander;
  failedAssertions = map (entry: entry.message) (
    builtins.filter (entry: !entry.assertion) system.assertions
  );
  oldHosts = [
    "gluck@gluck"
    "marlowe@cheroot"
    "gluck@wsl"
  ];
  oldDerivations = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = flake.homeConfigurations.${name}.activationPackage.drvPath;
    }) oldHosts
  );
  cleanOldHosts = builtins.all (
    name:
    let
      cfg = flake.homeConfigurations.${name}.config;
    in
    !(cfg.systemd.user.services ? figaro-commander) && !(cfg.home.sessionVariables ? FIGARO_STATE_DIR)
  ) oldHosts;
in
assert cleanOldHosts;
assert hostFailedAssertions == [ ];
assert host.boot.loader.systemd-boot.enable && !host.boot.loader.efi.canTouchEfiVariables;
assert host.boot.loader.efi.efiSysMountPoint == "/boot";
assert host.boot.initrd.systemd.enable && host.boot.initrd.systemd.tpm2.enable;
assert host.boot.initrd.luks.devices.merlin.crypttabExtraOpts == [ "tpm2-device=auto" ];
assert builtins.all (
  mount:
  builtins.all (option: builtins.elem option host.fileSystems.${mount}.options) [
    "compress=zstd"
    "noatime"
  ]
) btrfsMounts;
assert flake.inputs.merlin-figaro.rev == "fba39fc409d15c4fa504ac5bdcbd1d4c9ceb4abe";
assert hm.home.username == "jack" && hm.home.homeDirectory == "/home/jack";
assert integrated.xdg.configFile ? "figaro-merlin/skills/merlin-context.md";
assert hm.programs.figaro.package.version == "0.72.1";
assert !hm.programs.figaro.restartOnSwitch && !hm.systemd.user.startServices;
assert !integrated.programs.figaro.restartOnSwitch && !integrated.systemd.user.startServices;
assert !system.services.figaro.enable;
assert !(system.systemd.services ? figaro);
assert system.networking.hostName == "merlin";
assert system.users.users.jack.uid == 1000 && system.users.groups.jack.gid == 1000;
assert system.programs.niri.enable && system.services.greetd.enable;
assert !system.networking.networkmanager.enable;
assert system.networking.wireless.iwd.settings.General.EnableNetworkConfiguration;
assert system.services.resolved.enable;
assert system.systemd.network.networks."20-wired".matchConfig.Driver == "r8169";
assert builtins.all (m: builtins.elem m system.boot.blacklistedKernelModules) [
  "iwlwifi"
  "iwlmvm"
];
assert lib.hasPrefix "615." system.hardware.nvidia.package.version;
assert
  system.environment.etc
    ? "nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json";
assert builtins.any (p: lib.getName p == "merlin-diag") system.environment.systemPackages;
assert !system.systemd.services.systemd-hibernate.enable;
assert integrated.home.sessionVariables.FIGARO_STATE_DIR == "/home/jack/.local/state/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_CONFIG_DIR == "/home/jack/.config/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_CACHE_DIR == "/home/jack/.cache/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_RUNTIME_DIR == "\${XDG_RUNTIME_DIR}/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_NO_SELF_SPAWN == "1";
assert builtins.elem "FIGARO_ARIA" unit.Service.UnsetEnvironment;
assert builtins.elem "FIGARO_RUNTIME_DIR=%t/figaro-merlin" unit.Service.Environment;
assert builtins.elem "FIGARO_SYSTEMD_UNIT=figaro-commander.service" unit.Service.Environment;
assert integrated.home.sessionVariables.FIGARO_SYSTEMD_UNIT == "figaro-commander.service";
assert
  builtins.head unit.Service.ExecStart
  == "${lib.getExe integrated.programs.figaro.package} --angelus";
assert builtins.length failedAssertions == 2;
assert builtins.any (lib.hasInfix "root file system") failedAssertions;
assert builtins.any (lib.hasInfix "boot.loader.grub.devices") failedAssertions;
assert builtins.all (text: !(lib.hasInfix text integrated.home.activation.verifyCommanderRoot.data))
  [
    " new "
    " cast "
    " bind "
  ];
builtins.deepSeq oldDerivations {
  existingConsumerDerivations = oldDerivations;
  merlinHomeDerivation = flake.homeConfigurations."jack@merlin".activationPackage.drvPath;
  inherit failedAssertions;
  figaroRevision = flake.inputs.merlin-figaro.rev;
  rootOwner = "user:jack/figaro-commander.service";
  merlinToplevel = flake.nixosConfigurations.merlin.config.system.build.toplevel.drvPath;
  hardwareReady = true;
}

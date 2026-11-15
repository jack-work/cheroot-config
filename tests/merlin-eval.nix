let
  flake = builtins.getFlake "git+file://${toString ../.}";
  lib = flake.inputs.nixpkgs.lib;
  hm = flake.homeConfigurations."jack@merlin".config;
  system =
    (flake.inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ flake.nixosModules.merlin ];
    }).config;
  integrated = system.home-manager.users.jack;
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
assert !(flake.nixosConfigurations ? merlin);
assert flake.inputs.figaro.rev == "571857afeb39feb6a8e7a46eb84ecb160d47c3d0";
assert flake.inputs.merlin-figaro.rev == "180d4906346f73c403c2daa8cea299f30c75ed53";
assert hm.home.username == "jack" && hm.home.homeDirectory == "/home/jack";
assert hm.programs.figaro.package.version == "0.69.9";
assert !hm.programs.figaro.restartOnSwitch && !hm.systemd.user.startServices;
assert !integrated.programs.figaro.restartOnSwitch && !integrated.systemd.user.startServices;
assert !system.services.figaro.enable;
assert !(system.systemd.services ? figaro);
assert system.networking.hostName == "merlin";
assert system.users.users.jack.uid == 1000 && system.users.groups.jack.gid == 1000;
assert system.programs.niri.enable && system.services.greetd.enable;
assert
  system.networking.networkmanager.enable && system.networking.networkmanager.wifi.backend == "iwd";
assert !system.systemd.services.systemd-hibernate.enable;
assert integrated.home.sessionVariables.FIGARO_STATE_DIR == "/home/jack/.local/state/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_CONFIG_DIR == "/home/jack/.config/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_CACHE_DIR == "/home/jack/.cache/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_RUNTIME_DIR == "\${XDG_RUNTIME_DIR}/figaro-merlin";
assert integrated.home.sessionVariables.FIGARO_NO_SELF_SPAWN == "1";
assert builtins.elem "FIGARO_ARIA" unit.Service.UnsetEnvironment;
assert builtins.elem "FIGARO_RUNTIME_DIR=%t/figaro-merlin" unit.Service.Environment;
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
  hardwareReady = false;
}

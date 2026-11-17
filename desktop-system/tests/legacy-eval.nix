let
  current = builtins.getFlake "path:${toString ../.}";
  baseline = builtins.getFlake "git+file:///home/gluck/dev/cheroot-config?rev=5f6c2d5dd19ee7b7653fa5717f2a186897b3189c";
  names = [
    "gluck@gluck"
    "marlowe@cheroot"
    "gluck@wsl"
    "cig@gluck"
  ];
  describe =
    flake: name:
    let
      cfg = flake.homeConfigurations.${name}.config;
      lib = flake.inputs.nixpkgs.lib;
    in
    {
      packages = builtins.sort builtins.lessThan (map lib.getName cfg.home.packages);
      platform = {
        inherit (cfg.my.platform) desktopFromNix toolchainFromNix mediaFromNix;
      };
      shellAliases = cfg.programs.fish.shellAliases;
      gitUser = cfg.programs.git.settings.user or { };
    };
  comparisons = map (
    name:
    let
      before = describe baseline name;
      after = describe current name;
    in
    assert before.packages == after.packages;
    assert before.platform == after.platform;
    assert before.shellAliases == after.shellAliases;
    assert before.gitUser == after.gitUser;
    {
      inherit name;
      beforeDerivation = baseline.homeConfigurations.${name}.activationPackage.drvPath;
      afterDerivation = current.homeConfigurations.${name}.activationPackage.drvPath;
      packagesMatch = true;
      platformMatches = true;
      shellAliasesMatch = true;
      gitUserMatches = true;
    }
  ) names;
in
builtins.deepSeq comparisons comparisons

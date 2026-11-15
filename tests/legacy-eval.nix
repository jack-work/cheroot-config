let
  reference = "git+file://${toString ../.}";
  current = builtins.getFlake reference;
  baseline = builtins.getFlake "${reference}?rev=5f6c2d5dd19ee7b7653fa5717f2a186897b3189c";
  names = [
    "gluck@gluck"
    "marlowe@cheroot"
    "gluck@wsl"
  ];
  describe =
    flake: name:
    let
      cfg = flake.homeConfigurations.${name}.config;
      lib = flake.inputs.nixpkgs.lib;
    in
    {
      packages = map lib.getName cfg.home.packages;
      preflight = cfg.home.activation.preflight.data;
      platform = {
        inherit (cfg.my.platform) desktopFromNix toolchainFromNix mediaFromNix;
      };
      shellAliases = cfg.programs.fish.shellAliases;
    };
  comparisons = map (
    name:
    let
      before = describe baseline name;
      after = describe current name;
    in
    assert before.packages == after.packages;
    assert before.preflight == after.preflight;
    assert before.platform == after.platform;
    assert before.shellAliases == after.shellAliases;
    {
      inherit name;
      beforeDerivation = baseline.homeConfigurations.${name}.activationPackage.drvPath;
      afterDerivation = current.homeConfigurations.${name}.activationPackage.drvPath;
      packagesMatch = true;
      preflightMatches = true;
      platformMatches = true;
      shellAliasesMatch = true;
    }
  ) names;
in
builtins.deepSeq comparisons comparisons

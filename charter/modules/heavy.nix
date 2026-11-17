{
  flake.modules.nixos.heavy =
    { config, lib, ... }:
    let
      cfg = config.my.heavy;
    in
    {
      options.my.heavy = {
        enable = lib.mkEnableOption "system heavy.slice resource cap";
        cpuWeight = lib.mkOption {
          type = lib.types.int;
          default = 20;
        };
        ioWeight = lib.mkOption {
          type = lib.types.int;
          default = 20;
        };
        cpuQuota = lib.mkOption {
          type = lib.types.str;
          default = "1200%";
        };
        memoryMax = lib.mkOption {
          type = lib.types.str;
          default = "36G";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.slices.heavy = {
          description = "heavy background jobs";
          sliceConfig = {
            CPUWeight = cfg.cpuWeight;
            IOWeight = cfg.ioWeight;
            CPUQuota = cfg.cpuQuota;
            MemoryMax = cfg.memoryMax;
          };
        };
      };
    };

  flake.modules.homeManager.heavy =
    { config, lib, ... }:
    let
      cfg = config.my.heavy;
    in
    {
      options.my.heavy = {
        cpuWeight = lib.mkOption {
          type = lib.types.int;
          default = 20;
        };
        ioWeight = lib.mkOption {
          type = lib.types.int;
          default = 20;
        };
        cpuQuota = lib.mkOption {
          type = lib.types.str;
          default = "1200%";
        };
        memoryMax = lib.mkOption {
          type = lib.types.str;
          default = "36G";
        };
      };

      config.systemd.user.slices.heavy = {
        Unit = {
          Description = "heavy.sh jobs, on what the desktop leaves";
          X-SwitchMethod = "keep-old";
        };
        Slice = {
          CPUWeight = cfg.cpuWeight;
          IOWeight = cfg.ioWeight;
          CPUQuota = cfg.cpuQuota;
          MemoryMax = cfg.memoryMax;
        };
      };
    };
}

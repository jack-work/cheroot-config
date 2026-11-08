{ ... }:
{
  flake.modules.homeManager.heavy = {
    systemd.user.slices.heavy = {
      Unit = {
        Description = "heavy.sh jobs, on what the desktop leaves";
        X-SwitchMethod = "keep-old";
      };
      Slice = {
        CPUWeight = 20;
        IOWeight = 20;
        CPUQuota = "1200%";
        MemoryHigh = "26G";
        MemoryMax = "28G";
      };
    };
  };
}

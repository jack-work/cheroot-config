# flake-parts needs to know which systems to generate per-system outputs for.
# In the dendritic pattern even this is a module rather than a line in flake.nix.
{
  systems = [ "x86_64-linux" ];
}

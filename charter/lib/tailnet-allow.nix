{ lib }:
{
  config,
  from,
  port,
  interface ? "tailscale0",
}:
let
  nft = config.networking.nftables.enable;
  family = a: if lib.hasInfix ":" a then "ip6" else "ip";
  tool = a: if lib.hasInfix ":" a then "ip6tables" else "iptables";
  rule = a: "-i ${interface} -s ${a} -p tcp --dport ${toString port} -j nixos-fw-accept";
in
{
  networking.firewall.extraInputRules = lib.mkIf nft (
    lib.concatMapStrings (a: ''
      iifname "${interface}" ${family a} saddr ${a} tcp dport ${toString port} accept
    '') from
  );
  networking.firewall.extraCommands = lib.mkIf (!nft) (
    lib.concatMapStrings (a: ''
      ${tool a} -A nixos-fw ${rule a}
    '') from
  );
  networking.firewall.extraStopCommands = lib.mkIf (!nft) (
    lib.concatMapStrings (a: ''
      ${tool a} -D nixos-fw ${rule a} 2>/dev/null || true
    '') from
  );
}

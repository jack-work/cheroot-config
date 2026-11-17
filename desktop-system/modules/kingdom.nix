{
  flake.modules.homeManager.kingdom = {
    my.figaro.roster = {
      king-of-spain = {
        kind = "leader";
        form = "@96447061";
        purpose = "Root command: coordinates the estate under Gluck";
        charter = "The seat of spain: the NixOS mini-PC that is router, NAS, identity provider (Authelia+lldap), app host (kelliher-web/Caddy/cloudflared), git host (keel) and finance cache (kfin). The holder coordinates and keeps context GENERAL; specialists hold detail and are addressed by their own roles. Standing rules: spain is the house router, so deploys are cheap but REBOOTS ARE NOT — never restart spain without Gluck's explicit okay, and say so when a change needs one. Live state is read from the box, not remembered.";
      };
      jefe-estado-mayor = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@33986a45978384974714f033a3345f8a";
        purpose = "Project Italy plan and backlog";
        charter = "Holds the Project Italy long-term plan and backlog (~/.captains-log/workstreams/italy.md). Decomposes milestones into owned items and sends them to the King in batches for routing. Proposes the work queue (hub).";
      };
      figaro-engineer = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@ee9271497f3823d7f50922bec4899818";
        purpose = "Engineer regiment: builds and releases figaro";
        charter = "Builds and releases figaro: lanes on worktrees, gates, patch releases from main, reports to Gluck. Ledger: ~/.local/state/impresario (README.md, HANDOFF.md).";
      };
      el-mayor = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@2b4fe37fc20436ff3123373ed0a504f6";
        purpose = "Colonel for system flakes";
        charter = "Colonel for system flakes: nixos-system-charter, cheroot-config, spain-flake source, Merlin integration. Stages on keel branches; never switches hosts or deploys Spain.";
      };
    };
  };
}

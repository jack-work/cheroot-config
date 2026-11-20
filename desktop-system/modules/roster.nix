{ ... }:
let
  kic = [
    "opus5-kic"
    "sonn5-kic"
    "succession-standard"
  ];
  command = kic ++ [
    "opus5"
    "opus5-kic2"
    "hk"
    "short"
    "sonn5"
    "review-sonnet"
  ];
  fable = [
    "fable-kic"
    "fable-kic2"
  ];
  lanesOf =
    lead: names:
    builtins.listToAttrs (
      map (n: {
        name = n;
        value = "fleet.lane.${lead}.${n}";
      }) names
    );
in
{
  flake.modules.homeManager.roster = {
    my.figaro.outfits = {
      "model/opus5-kic".layers = [
        "house"
        "via-rou2"
      ];
      "model/opus5-kic".system.model = "anthropic-kic/claude-opus-5-5";
      "model/sonn5-kic".layers = [
        "house"
        "via-rou2"
      ];
      "model/sonn5-kic".system.model = "anthropic-kic/claude-sonnet-5-5";
      "model/opus5-kic2".layers = [
        "house"
        "via-rou2"
      ];
      "model/opus5-kic2".system.model = "anthropic-kic-2/claude-opus-5-5";
      "model/review-sonnet".layers = [
        "house"
        "via-rou2"
      ];
      "model/review-sonnet".system.model = "anthropic-kic/claude-sonnet-5-5";
      "model/fable-kic".layers = [
        "house"
        "via-rou2"
      ];
      "model/fable-kic".system.model = "anthropic-kic/claude-fable-5-2";
      "model/fable-kic2".layers = [
        "house"
        "via-rou2"
      ];
      "model/fable-kic2".system.model = "anthropic-kic-2/claude-fable-5-2";
    };

    my.roles.orchestration = "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off. Every lane is a captains-log index, listed under lanes on its lead's role form (fleet.lane.<lead>.<lane>): a child fanned out on a lane gets that index in its brief and resolves it with cl cite and cl show before acting.";
    my.roles.standing.handoff-warm = "Gluck 11-19: (1) at about 50 percent context and idle, succeed NOW on a warm cache (finish any open Spain window or Inspector read first). (2) Keep the handoff warm: a short dated captains-log entry per event, handle spain.seats.<seat>, kind handoff; the handoff doc indexes them; at succession write only the delta. Rule: ~/.captains-log/2026/11/19/warm-handoffs-and-early-succession.md";

    my.roles.roles = {
      king-of-spain = {
        form = "@96447061";
        title = "King of Spain";
        charter = ../duties/king-of-spain.md;
        outfits = command ++ fable;
        birth = "default,succession-standard,opus5-kic";
        standing.handoff-warm = "Gluck 11-19 ~11:20: (1) seats near their handover line (about 50 percent context and idle) succeed NOW, not later on a cold cache: the King sweeps the roster and nudges each; (2) every seat keeps its handoff document warm in captains-log (a short dated entry per event) so succession needs only a final delta. Put it in the charter plan and each seat's brief.";
      };
      backend-engineer = {
        form = "@4f6f262b6205e70f7e27a38440872c40";
        title = "Backend Engineer";
        charter = ../duties/backend-engineer.md;
        outfits = kic ++ [
          "opus5"
          "short"
        ];
        lanes = lanesOf "backend" [
          "rou2"
          "keel"
          "spain-executor"
          "identity"
          "edge"
          "flakes-charter"
          "merlin"
          "github-watcher"
        ];
      };
      frontend-engineer = {
        form = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
        title = "Frontend Engineer";
        charter = ../duties/frontend-engineer.md;
        outfits = kic ++ [ "opus5" ] ++ fable;
        lanes = lanesOf "frontend" [
          "scope-ui"
          "order-site"
          "approvals-app"
          "big-tv"
          "writer-resume"
        ];
      };
      figaro-engineer = {
        form = "@ee9271497f3823d7f50922bec4899818";
        title = "Figaro Engineer";
        charter = ../duties/figaro-engineer.md;
        outfits = command;
        lanes = lanesOf "figaro" [
          "daemon-releases"
          "authz-carve"
          "aria-log"
          "approvals-server"
          "king-authority"
          "review-pool"
        ];
      };
      herald = {
        form = "@2c1645942f894dd40d9dfcfb97619c58";
        title = "Herald";
        charter = ../duties/herald.md;
        outfits = kic;
        lanes.threads = "fleet.lane.herald.threads";
      };
      release-engineer = {
        form = "@460d7227d652f5af0603f96290376b01";
        title = "Release Engineer";
        charter = ../duties/release-engineer.md;
        outfits = kic;
        index = "fleet.release";
      };
    };
  };
}

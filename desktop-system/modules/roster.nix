{ ... }:
let
  kic = [
    "opus5-kic"
    "opus5-kic2"
    "sonn5-kic"
    "succession-standard"
  ];
  command = kic ++ [
    "opus5"
    "hk"
    "short"
    "sonn5"
    "review-sonnet"
  ];
  copilot = [
    "sonncop"
    "default-copilot"
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
      "model/sonncop" = {
        layers = [
          "house"
          "via-copilot"
        ];
        system.model = "claude-sonnet-5.5";
      };
      "default/default-copilot" = {
        layers = [
          "house"
          "via-copilot"
        ];
        system = {
          eager_tool_streaming = true;
          ttl = "7d";
          model = "claude-opus-5.5";
        };
      };
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
      "default/default_kic".layers = [
        "house"
        "via-rou2"
      ];
      "default/default_kic".system = {
        model = "anthropic-kic/claude-opus-5-5";
        eager_tool_streaming = true;
        ttl = "7d";
        reap_if_empty = true;
        methods.enabled = true;
        methods.reasoning-effort.keep_cache = false;
      };
    };

    my.roles.orchestration = "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off. Every lane is a captains-log index, listed under lanes on its lead's role form (fleet.lane.<lead>.<lane>): a child fanned out on a lane gets that index in its brief and resolves it with cl cite and cl show before acting.";
    my.roles.standing.handoff-warm = "Gluck 11-19: (1) at about 50 percent context and idle, succeed NOW on a warm cache (finish any open Spain window or Inspector read first). (2) Keep the handoff warm: a short dated captains-log entry per event, handle spain.seats.<seat>, kind handoff; the handoff doc indexes them; at succession write only the delta. Rule: ~/.captains-log/2026/11/19/warm-handoffs-and-early-succession.md";

    my.roles.queueContract = "https://keel.kelliher.info/_keel/jack-captains-log-entries/blob/3201b21b3bc6f65758d653e45544d11969136ecd/2026/11/25/work-orders-contract.md";
    my.roles.roles = {
      king-of-spain = {
        form = "@96447061";
        title = "King of Spain";
        charter = ../duties/king-of-spain.md;
        seat = "king";
        outfits = command ++ fable ++ copilot;
        standing.handoff-warm = "Gluck 11-19 ~11:20: (1) seats near their handover line (about 50 percent context and idle) succeed NOW, not later on a cold cache: the King sweeps the roster and nudges each; (2) every seat keeps its handoff document warm in captains-log (a short dated entry per event) so succession needs only a final delta. Put it in the charter plan and each seat's brief.";
      };
      backend-engineer = {
        form = "@4f6f262b6205e70f7e27a38440872c40";
        title = "Backend Knight";
        charter = ../duties/backend-knight.md;
        seat = "knight";
        regiment = "backend";
        reportsTo = "king-of-spain";
        fanout.max_children = 1;
        queue.kinds = [
          "work"
          "handoff"
        ];
        outfits =
          kic
          ++ [
            "opus5"
            "short"
          ]
          ++ copilot;
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
        title = "Frontend Knight";
        charter = ../duties/frontend-knight.md;
        seat = "knight";
        regiment = "frontend";
        reportsTo = "king-of-spain";
        fanout.max_children = 1;
        queue.kinds = [
          "work"
          "handoff"
        ];
        outfits = kic ++ [ "opus5" ] ++ fable ++ copilot;
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
        seat = "lead";
        regiment = "figaro";
        reportsTo = "king-of-spain";
        queue.kinds = [
          "work"
          "handoff"
        ];
        outfits = command ++ copilot;
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
        seat = "herald";
        reportsTo = "king-of-spain";
        queue.kinds = [
          "work"
          "handoff"
        ];
        outfits = kic ++ copilot;
        lanes.threads = "fleet.lane.herald.threads";
      };
      backend-strategist = {
        form = "@db5727fe69feb38e67959086ecabcad3";
        title = "Backend Strategist";
        seat = "strategist";
        regiment = "backend";
        reportsTo = "backend-engineer";
        fanout.max_children = 1;
      };
      frontend-strategist = {
        form = "@581b64cf";
        title = "Frontend Strategist";
        seat = "strategist";
        regiment = "frontend";
        reportsTo = "frontend-engineer";
        fanout.max_children = 1;
      };
      inspector = {
        title = "Inspector";
        seat = "inspector";
        reportsTo = "king-of-spain";
        reviewers.max_children = 1;
      };
      release-engineer = {
        form = "@460d7227d652f5af0603f96290376b01";
        title = "Deployment Engineer";
        charter = ../duties/deployment-engineer.md;
        seat = "edge";
        reportsTo = "king-of-spain";
        fanout.max_children = 1;
        queue.kinds = [ "deploy" ];
        outfits = kic ++ copilot;
        index = "fleet.release";
      };
    };
  };
}

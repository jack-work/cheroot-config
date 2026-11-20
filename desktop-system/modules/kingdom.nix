{ inputs, ... }:
let
  k = inputs.charter.lib.kingdom;
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

  orchestration = "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off. Every lane is a captains-log index, listed under lanes on its Colonel's role form (fleet.lane.<regiment>.<lane>): a child fanned out on a lane gets that index in its brief and resolves it with cl cite and cl show before acting.";

  lanesOf =
    regiment: names:
    builtins.listToAttrs (
      map (n: {
        name = n;
        value = "fleet.lane.${regiment}.${n}";
      }) names
    );

in
{
  flake.modules.homeManager.kingdom =
    { lib, ... }:
    {
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

      my.kingdom.root = "king-of-spain";
      my.kingdom.orchestration = orchestration;
      my.kingdom.standing.handoff-warm = "Gluck 11-19: (1) at about 50 percent context and idle, succeed NOW on a warm cache (finish any open Spain window or Inspector read first). (2) Keep the handoff warm: a short dated captains-log entry per event, handle spain.seats.<seat>, kind handoff; the handoff doc indexes them; at succession write only the delta. Rule: ~/.captains-log/2026/11/19/warm-handoffs-and-early-succession.md";

      my.kingdom.seats = lib.mkMerge [
        {
          king-of-spain = k.seat {
            mode = "apply";
            role = "@96447061";
            kind = "leader";
            title = "King of Spain";
            purpose = "Root command: coordinates the estate under Gluck";
            duty = ../duties/king-of-spain.md;
            reach = "fleet";
            reportsTo = [ "backend-engineer" ];
            outfits = command ++ [
              "fable-kic"
              "fable-kic2"
            ];
            standing.handoff-warm = "Gluck 11-19 ~11:20: (1) seats near their handover line (about 50 percent context and idle) succeed NOW, not later on a cold cache: the King sweeps the roster and nudges each; (2) every seat keeps its handoff document warm in captains-log (a short dated entry per event) so succession needs only a final delta. Put it in the charter plan and each seat's brief.";
          };

          figaro-engineer = k.seat {
            mode = "apply";
            role = "@ee9271497f3823d7f50922bec4899818";
            kind = "leader";
            title = "Figaro Engineer";
            purpose = "Colonel of the figaro regiment: builds and releases figaro";
            duty = ../duties/figaro-engineer.md;
            reach = "fleet";
            reportsTo = [ "king-of-spain" ];
            outfits = command;
            lanes =
              lanesOf "figaro" [
                "daemon-releases"
                "authz-carve"
                "aria-log"
                "approvals-server"
                "king-authority"
              ]
              // {
                review-pool = "fleet.lane.review-pool";
              };
          };

          backend-engineer = k.seat {
            mode = "apply";
            role = "@4f6f262b6205e70f7e27a38440872c40";
            kind = "leader";
            title = "Backend Engineer";
            purpose = "Colonel of the backend regiment: flakes, keel, rou2, identity, edge, Spain deploys and the Inspector pass, run as lanes";
            duty = ../duties/backend-engineer.md;
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
              "inspector"
              "github-watcher"
            ];
          };

          frontend-engineer = k.seat {
            mode = "apply";
            role = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
            kind = "leader";
            title = "Frontend Engineer";
            purpose = "Colonel of the frontend regiment: zanni, figar.org visual components and the sites that wear them";
            duty = ../duties/frontend-engineer.md;
            outfits = kic ++ [
              "opus5"
              "fable-kic"
              "fable-kic2"
            ];
            lanes = lanesOf "frontend" [
              "scope-ui"
              "order-site"
              "approvals-app"
              "big-tv"
              "writer-resume"
            ];
          };

          herald = k.seat {
            mode = "apply";
            role = "@2c1645942f894dd40d9dfcfb97619c58";
            kind = "leader";
            title = "Herald";
            purpose = "The Adjutant: conversations, answers and orders between Gluck and figaros";
            duty = ../duties/herald.md;
            outfits = kic;
            lanes.threads = "fleet.lane.herald.threads";
          };
        }

      ];
    };
}

{ ... }:
let
  max = [
    "opus5-max"
    "sonn5-max"
  ];
  seat = max ++ kic ++ copilot;
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
      "model/opus5-max".layers = [
        "house"
        "via-rou2"
      ];
      "model/opus5-max".system.model = "anthropic-max/claude-opus-5-5";
      "model/sonn5-max".layers = [
        "house"
        "via-rou2"
      ];
      "model/sonn5-max".system.model = "anthropic-max/claude-sonnet-5-5";
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
    my.charter = {
      centralCommand = {
        form = "@96447061";
        title = "King of Spain";
        charter = ../duties/king-of-spain.md;
        outfits = max ++ command ++ fable ++ copilot;
        standing.handoff-warm = "Gluck 11-19 ~11:20: (1) seats near their handover line (about 50 percent context and idle) succeed NOW, not later on a cold cache: the King sweeps the roster and nudges each; (2) every seat keeps its handoff document warm in captains-log (a short dated entry per event) so succession needs only a final delta. Put it in the charter plan and each seat's brief.";
      };
      regiments.backend = {
        lead = {
          form = "@86e182fcf2629937d3a5928dd5701a6d";
          title = "Backend Lead";
          outfits = seat;
        };
        handoff.form = "@b209cbd770c316f06f4ca504fcad3d7b";
        strategist = {
          form = "@db5727fe69feb38e67959086ecabcad3";
          title = "Backend Strategist";
          outfits = seat;
          fanout.max_children = 1;
          lanes = lanesOf "backend" [
            "rou2"
            "keel"
            "spain-executor"
            "identity"
            "edge"
            "flakes-charter"
            "merlin"
            "github-watcher"
            "herald"
            "telefono"
          ];
        };
        knight = {
          form = "@4f6f262b6205e70f7e27a38440872c40";
          title = "Backend Knight";
          charter = ../duties/backend-knight.md;
          fanout.max_children = 1;
          outfits =
            max
            ++ kic
            ++ [
              "opus5"
              "short"
            ]
            ++ copilot;
        };
      };
      regiments.frontend = {
        lead = {
          form = "@174f1c5bfcf0e42ee7d94d11b2d69df4";
          title = "Frontend Lead";
          outfits = seat;
        };
        handoff.form = "@3a187137300c27daac0e2f8c3a3cf0cd";
        strategist = {
          form = "@581b64cf";
          title = "Frontend Strategist";
          outfits = seat;
          fanout.max_children = 1;
          lanes = lanesOf "frontend" [
            "scope-ui"
            "order-site"
            "approvals-app"
            "big-tv"
            "writer-resume"
          ];
        };
        knight = {
          form = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
          title = "Frontend Knight";
          charter = ../duties/frontend-knight.md;
          fanout.max_children = 1;
          outfits = max ++ kic ++ [ "opus5" ] ++ fable ++ copilot;
        };
      };
      regiments.figaro = {
        lead = {
          form = "@ee9271497f3823d7f50922bec4899818";
          title = "Figaro Engineer";
          charter = ../duties/figaro-engineer.md;
          outfits = max ++ command ++ copilot;
          lanes = lanesOf "figaro" [
            "daemon-releases"
            "authz-carve"
            "aria-log"
            "approvals-server"
            "king-authority"
            "review-pool"
          ];
        };
        handoff.form = "@3f92d344e95b342ed9e42ced7b71e817";
        strategist = {
          form = "@5940d8060feee07aa39a076965e2ed1a";
          title = "Figaro Strategist";
          outfits = seat;
          fanout.max_children = 1;
        };
        knight = {
          form = "@563062e9582afc2589b4379f9ee8ad63";
          title = "Figaro Knight";
          outfits = seat;
          fanout.max_children = 1;
        };
      };
      inspector = {
        seat = {
          form = "@a9243cc34e95162e82f0f51c06ef7eb4";
          title = "Inspector";
          outfits = seat;
        };
        form.form = "@c27bc995e86adc157b02d8c06a6e7ba6";
        reviewers.max_children = 1;
      };
      edge = {
        seat = {
          form = "@460d7227d652f5af0603f96290376b01";
          title = "Edge Engineer";
          charter = ../duties/edge-engineer.md;
          fanout.max_children = 1;
          outfits = max ++ kic ++ copilot;
          index = "fleet.release";
        };
        deploy.form = "@e954982f39b57de82e5cb0404afb7310";
      };
    };
  };
}

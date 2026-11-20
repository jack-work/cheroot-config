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
  renamed = "2026-12-18";

  orchestration = "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off. Every lane is a captains-log index, listed under lanes on its Colonel's role form (fleet.lane.<regiment>.<lane>): a child fanned out on a lane gets that index in its brief and resolves it with cl cite and cl show before acting.";

  lanesOf =
    regiment: names:
    builtins.listToAttrs (
      map (n: {
        name = n;
        value = "fleet.lane.${regiment}.${n}";
      }) names
    );

  agreement = [
    "{strategist} builds the whole plan with transient forks and keeps the final vision. It restacks the work into incremental, non-conflicting commits for {knight}, and again as {knight} lands fixes on main. A hard rejection sends that part back to {strategist}, not into patch-on-patch."
    "{knight} carries only mutually non-conflicting changes at a time, produces the validated build of each and asks the Reviewer Pool for a reviewer dressed in {reviewer-outfit}. It never merges to main."
    "{knight} and {strategist} talk directly with figaro send -f: {strategist} warns of anything found in later parts before {knight} reaches them; {knight} asks when a review makes a part unclear."
    "Fan-out forks and reviewers are transient: finite system.ttl, never seats, retired with --ttl {retire-ttl} once their harvest (what they did, branch and sha, evidence, open obligations, lessons) is in a dated captains-log entry."
    "Ask your parent for quota before you need it, in one line: what for, how many, how long."
  ];

  regimentKinds = name: {
    strategist = {
      outfits = kic ++ [
        "regiment-${name}-strategist"
        "succession-cache"
        "opus5"
        "opus5-kic2"
      ];
      provider = "rou2";
      model = "anthropic-kic-2/claude-opus-5-5";
      limit = {
        children = 7;
        quota = 14;
      };
    };
    knight = {
      outfits = kic ++ [
        "regiment-${name}-knight"
        "succession-cache"
        "opus5"
        "opus5-kic2"
      ];
      provider = "rou2";
      model = "anthropic-kic-2/claude-opus-5-5";
      limit.children = 1;
    };
    reviewer = {
      provider = "gemini";
      model = "gemini-4-carbon";
    };
  };

  regiment =
    name: leader: seats:
    k.regiment {
      inherit
        name
        leader
        seats
        orchestration
        agreement
        ;
      kinds = regimentKinds name;
      successionLayers = [ "succession-cache" ];
    };
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
      };

      my.kingdom.root = "king-of-spain";
      my.kingdom.orchestration = orchestration;
      my.kingdom.standing.handoff-warm = "Gluck 11-19: (1) at about 50 percent context and idle, succeed NOW on a warm cache (finish any open Spain window or Inspector read first). (2) Keep the handoff warm: a short dated captains-log entry per event, handle spain.seats.<seat>, kind handoff; the handoff doc indexes them; at succession write only the delta. Rule: ~/.captains-log/2026/11/19/warm-handoffs-and-early-succession.md";
      my.kingdom.whenFull = "If a fork or new is refused for fan-out quota, or you are over system.fanout.max_children, retire or kill children whose work is done (harvest first) until you are under; a retired or killed child frees its slot at once. Do not ask for a higher limit until you have.";

      my.kingdom.seats = lib.mkMerge [
        {
          king-of-spain = k.seat {
            role = "@96447061";
            kind = "leader";
            title = "King of Spain";
            purpose = "Root command: coordinates the estate under Gluck";
            duty = ../duties/king-of-spain.md;
            limit.children = 24;
            reach = "fleet";
            reportsTo = [ "operator" ];
            outfits = command;
            standing.handoff-warm = "Gluck 11-19 ~11:20: (1) seats near their handover line (about 50 percent context and idle) succeed NOW, not later on a cold cache: the King sweeps the roster and nudges each; (2) every seat keeps its handoff document warm in captains-log (a short dated entry per event) so succession needs only a final delta. Put it in the charter plan and each seat's brief.";
            forward.jefe-estado-mayor = renamed;
            aliases = {
              coordinador = k.companion {
                role = "@042d641e";
                title = "Coordinador de Spain";
                purpose = "The spain deploy queue and switch guard, a King companion";
                duty = ../duties/coordinador.md;
                outfits = kic;
              };
              identity-monitor = k.companion {
                role = "@5d998ccdb6086ee4ad53d73d376d968a";
                purpose = "The figaro identity plan monitor, a King companion";
              };
              planner = k.alias "@33986a45978384974714f033a3345f8a";
            };
          };

          figaro-engineer = k.seat {
            role = "@ee9271497f3823d7f50922bec4899818";
            kind = "leader";
            title = "Figaro Engineer";
            purpose = "Colonel of the figaro regiment: builds and releases figaro";
            duty = ../duties/figaro-engineer.md;
            limit.children = 20;
            reach = "fleet";
            reportsTo = [ "king-of-spain" ];
            outfits = command;
            lanes = lanesOf "figaro" [
              "daemon-releases"
              "authz-carve"
              "aria-log"
              "approvals-server"
              "king-authority"
            ];
            aliases.el-arquitecto = k.alias "@edea54025f3f3c6c1d8c2b27439d35f3";
          };

          backend-engineer = k.seat {
            role = "@4f6f262b6205e70f7e27a38440872c40";
            kind = "leader";
            title = "Backend Engineer";
            purpose = "Colonel of the backend regiment: flakes, keel, rou2, identity, edge, Spain deploys and the Inspector pass, run as lanes";
            duty = ../duties/backend-engineer.md;
            limit = {
              children = 12;
              quota = 12;
            };
            outfits = kic ++ [
              "opus5"
              "short"
            ];
            forward = {
              el-aduanero = renamed;
              quartermaster = renamed;
            };
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
            aliases = {
              el-mayor = k.lane {
                role = "@2b4fe37fc20436ff3123373ed0a504f6";
                lane = "flakes-charter";
              };
              el-taller = k.lane {
                role = "@2b443573385ce498dc40d0f5a672dd2a";
                lane = "keel";
              };
              rou2-engineer = k.lane {
                role = "@f48f567a727d703effa5e2fa13ebd625";
                lane = "rou2";
              };
              el-llavero = k.lane {
                role = "@a06b145cf1a6169789065ff3aae90646";
                lane = "identity";
              };
              el-zocalo = k.lane {
                role = "@0e3305315544cd50fac67c489d4df4f6";
                lane = "edge";
              };
              operator = k.lane {
                role = "@662ee4fedbd0fdbad7ad6adef20cdeee";
                lane = "spain-executor";
                forward.el-zapador = renamed;
              };
              edge = k.lane {
                role = "@b906c598b1857b6bfe350e077cf67ff6";
                lane = "spain-executor";
              };
              inspector = k.lane {
                role = "@53c6b72b";
                lane = "inspector";
                forward.el-inspector = renamed;
              };
              github-watcher = k.lane {
                role = "@443f4126721e7a980bbc9c68e8aede77";
                lane = "github-watcher";
                forward.el-centinela = renamed;
              };
              merlin-migration = k.lane {
                role = "@4a845160c69f98a0412c5dc4f28e8b70";
                lane = "merlin";
              };
            };
          };

          frontend-engineer = k.seat {
            role = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
            kind = "leader";
            title = "Frontend Engineer";
            purpose = "Colonel of the frontend regiment: zanni, figar.org visual components and the sites that wear them";
            duty = ../duties/frontend-engineer.md;
            limit.children = 3;
            outfits = kic ++ [ "opus5" ];
            forward.il-zanni = renamed;
            lanes = lanesOf "frontend" [
              "scope-ui"
              "order-site"
              "approvals-app"
              "big-tv"
              "writer-resume"
            ];
            aliases = {
              writer = k.lane {
                role = "@c204f2a0188fa5864b75db09e06dd266";
                lane = "writer-resume";
                forward.el-escribano = renamed;
              };
              big-tv = k.lane {
                role = "@2e0bb68c36211dbd2023bc693b4c682c";
                lane = "big-tv";
              };
            };
          };

          herald = k.seat {
            role = "@2c1645942f894dd40d9dfcfb97619c58";
            kind = "leader";
            title = "Herald";
            purpose = "The Adjutant: conversations, answers and orders between Gluck and figaros";
            duty = ../duties/herald.md;
            limit.children = 1;
            outfits = kic;
            forward.el-pregonero = renamed;
            lanes.threads = "fleet.lane.herald.threads";
          };

          reviewer-pool = k.seat {
            role = "@9e5bdab374ebdf583434860ff1fa9955";
            kind = "reviewer";
            title = "Reviewer Pool";
            purpose = "Shared review pool: one short-lived reviewer fork per change, for every regiment";
            duty = ../duties/reviewer-pool.md;
            limit.children = 5;
            outfits = kic ++ [
              "review-sonnet"
              "opus5-kic2"
              "regiment-figaro-reviewer"
              "regiment-backend-reviewer"
              "regiment-frontend-reviewer"
            ];
            forward.figaro-review-steward = renamed;
            lanes.review-pool = "fleet.lane.review-pool";
          };
        }

        (regiment "figaro" "figaro-engineer" {
          figaro-strategist = {
            kind = "strategist";
            role = "@9bf485c24507fe8484a001c18a1b84cc";
            title = "Figaro Strategist";
            purpose = "Thinker of the figaro regiment: plans the kingdom and fans out its parts";
            handoff = "/home/gluck/.local/state/impresario/handoff/strategist-permissions.md";
            duty = ../duties/figaro-strategist.md;
          };
          figaro-knight = {
            kind = "knight";
            role = "@d121c4041785b13c6261d6055f113f8d";
            title = "Figaro Knight";
            purpose = "Vanguard of the figaro regiment: ships the Strategist's parts as validated builds";
            handoff = "/home/gluck/.local/state/impresario/handoff/vanguard-permissions.md";
            duty = ../duties/figaro-knight.md;
          };
        })

        (regiment "backend" "backend-engineer" {
          backend-strategist = {
            kind = "strategist";
            title = "Backend Strategist";
            purpose = "Thinker of the backend regiment: plans across its lanes and fans out parts";
            duty = "Plans the backend regiment's work across its lanes (fleet.lane.backend.*), fans out forks that implement parts, and hands non-conflicting changes to the Backend Knight. Reports to the Backend Engineer.";
          };
          backend-knight = {
            kind = "knight";
            title = "Backend Knight";
            purpose = "Vanguard of the backend regiment: ships the Strategist's parts as validated builds";
            duty = "Ships what the Backend Strategist hands off as validated builds and Spain candidates, asks the Reviewer Pool and the Inspector pass for review, never switches Spain or merges to main. Reports to the Backend Engineer.";
          };
        })

        (regiment "frontend" "frontend-engineer" {
          frontend-strategist = {
            kind = "strategist";
            title = "Frontend Strategist";
            purpose = "Thinker of the frontend regiment, also serving Herald";
            duty = "Plans the frontend regiment's work across its lanes (fleet.lane.frontend.*) and Herald's (fleet.lane.herald.threads), fans out forks that implement parts, and hands non-conflicting changes to the Frontend Knight. Reports to the Frontend Engineer; takes Herald's work from Herald.";
          };
          frontend-knight = {
            kind = "knight";
            title = "Frontend Knight";
            purpose = "Vanguard of the frontend regiment, also serving Herald";
            duty = "Ships what the Frontend Strategist hands off, for Frontend and for Herald, as validated builds, asks the Reviewer Pool for review, never merges to main. Reports to the Frontend Engineer.";
          };
        })
      ];
    };
}

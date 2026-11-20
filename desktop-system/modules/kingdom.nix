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
            };
          };

          figaro-engineer = k.seat {
            role = "@ee9271497f3823d7f50922bec4899818";
            kind = "leader";
            title = "Figaro Engineer";
            purpose = "Engineer regiment: builds and releases figaro";
            duty = ../duties/figaro-engineer.md;
            limit.children = 10;
            reach = "fleet";
            reportsTo = [ "king-of-spain" ];
            outfits = command;
            aliases.el-arquitecto = k.alias "@edea54025f3f3c6c1d8c2b27439d35f3";
          };

          reviewer = k.seat {
            role = "@53c6b72b";
            kind = "reviewer";
            title = "Reviewer";
            purpose = "Reviews spain auth, secrets and deploy deltas";
            duty = ../duties/reviewer.md;
            limit.children = 5;
            outfits = kic;
            forward.el-inspector = renamed;
          };

          operator = k.seat {
            role = "@662ee4fedbd0fdbad7ad6adef20cdeee";
            kind = "steward";
            title = "Operator";
            purpose = "Spain deployments, release windows and acceptance, in windows the King names";
            duty = ../duties/operator.md;
            limit.children = 2;
            outfits = kic;
            forward.el-zapador = renamed;
            aliases.edge = k.alias "@b906c598b1857b6bfe350e077cf67ff6";
          };

          backend-engineer = k.seat {
            role = "@4f6f262b6205e70f7e27a38440872c40";
            kind = "leader";
            title = "Backend Engineer";
            purpose = "System flakes, keel, rou2, identity, edge and messaging; areas run as forks";
            limit.children = 6;
            outfits = kic ++ [
              "opus5"
              "short"
            ];
            forward = {
              el-aduanero = renamed;
              quartermaster = renamed;
            };
            aliases = {
              el-mayor = k.alias "@2b4fe37fc20436ff3123373ed0a504f6";
              el-taller = k.alias "@2b443573385ce498dc40d0f5a672dd2a";
              rou2-engineer = k.alias "@f48f567a727d703effa5e2fa13ebd625";
              el-llavero = k.alias "@a06b145cf1a6169789065ff3aae90646";
              el-zocalo = k.alias "@0e3305315544cd50fac67c489d4df4f6";
              el-pregonero = k.alias "@2c1645942f894dd40d9dfcfb97619c58";
            };
          };

          frontend-engineer = k.seat {
            role = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
            kind = "leader";
            title = "Frontend Engineer";
            purpose = "zanni and figar.org visual components, and the sites that wear them";
            duty = ../duties/frontend-engineer.md;
            limit.children = 3;
            outfits = kic ++ [ "opus5" ];
            forward.il-zanni = renamed;
          };

          big-tv = k.seat {
            role = "@2e0bb68c36211dbd2023bc693b4c682c";
            kind = "steward";
            title = "Big TV";
            purpose = "tv.kelliher.info";
            duty = ../duties/big-tv.md;
            limit = {
              children = 1;
              quota = 2;
            };
            outfits = kic;
          };

          planner = k.seat {
            role = "@33986a45978384974714f033a3345f8a";
            kind = "steward";
            title = "Planner";
            purpose = "Project Italy plan and backlog";
            duty = ../duties/planner.md;
            limit.children = 2;
            outfits = kic;
            forward.jefe-estado-mayor = renamed;
          };

          writer = k.seat {
            role = "@c204f2a0188fa5864b75db09e06dd266";
            kind = "steward";
            title = "Writer";
            purpose = "jack.kelliher.info and Gluck's résumé";
            duty = ../duties/writer.md;
            limit.children = 1;
            outfits = kic;
            forward.el-escribano = renamed;
          };

          github-watcher = k.seat {
            role = "@443f4126721e7a980bbc9c68e8aede77";
            kind = "steward";
            title = "GitHub Watcher";
            purpose = "Watches GitHub pushes and forwards them to the seat that owns the repo";
            limit.children = 0;
            outfits = [ ];
            forward.el-centinela = renamed;
          };

          merlin-migration = k.seat {
            role = "@4a845160c69f98a0412c5dc4f28e8b70";
            kind = "steward";
            title = "Merlin Migration";
            purpose = "Merlin's install and cutover from the old gluck; transient";
            limit.children = 1;
            outfits = kic;
          };
        }

        (k.regiment {
          name = "figaro";
          leader = "figaro-engineer";
          successionLayers = [ "succession-cache" ];
          seats = {
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
            figaro-review-steward = {
              kind = "steward";
              role = "@9e5bdab374ebdf583434860ff1fa9955";
              title = "Figaro Review Steward";
              purpose = "Keeps the figaro regiment's reviewer pool";
              handoff = "/home/gluck/.local/state/impresario/handoff/review-steward.md";
              duty = ../duties/figaro-review-steward.md;
            };
          };
          kinds = {
            strategist = {
              outfits = kic ++ [
                "regiment-figaro-strategist"
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
                "regiment-figaro-knight"
                "succession-cache"
                "opus5"
                "opus5-kic2"
              ];
              provider = "rou2";
              model = "anthropic-kic-2/claude-opus-5-5";
              limit.children = 1;
            };
            steward = {
              outfits = kic ++ [
                "regiment-figaro-steward"
                "succession-cache"
                "review-sonnet"
                "opus5-kic2"
                "regiment-figaro-reviewer"
              ];
              provider = "gemini";
              model = "gemini-4-carbon";
              limit.children = 3;
            };
            reviewer = {
              provider = "gemini";
              model = "gemini-4-carbon";
            };
          };
        })
      ];
    };
}

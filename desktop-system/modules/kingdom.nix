{
  flake.modules.homeManager.kingdom = {
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
    };
    my.figaro.fanoutWhenFull = "If a fork or new is refused for fan-out quota, or you are over system.fanout.max_children, retire or kill children whose work is done (harvest first) until you are under; a retired or killed child frees its slot at once. Do not ask for a higher limit until you have.";
    my.figaro.regiments.figaro = {
      leader = "figaro-engineer";
      seats = {
        figaro-strategist = {
          kind = "strategist";
          title = "Figaro Strategist";
          form = "@9bf485c24507fe8484a001c18a1b84cc";
          purpose = "Thinker of the figaro regiment: plans the kingdom and fans out its parts";
          handoff = "/home/gluck/.local/state/impresario/handoff/strategist-permissions.md";
          charter = "The thinker for the whole kingdom plan (plans/kingdom-charter.md, both tracks: Permissions and Estate). Owns the north-star on keel design/kingdom, fans out opus forks that implement parts, merges parts as they become ready and hands non-conflicting changes to the Knight. May ask the Review Steward for an early review of the whole. Reports to @ee927149.";
        };
        figaro-knight = {
          kind = "knight";
          title = "Figaro Knight";
          form = "@d121c4041785b13c6261d6055f113f8d";
          purpose = "Vanguard of the figaro regiment: ships the Strategist's parts as validated builds";
          handoff = "/home/gluck/.local/state/impresario/handoff/vanguard-permissions.md";
          charter = "Ships what the Strategist hands off: carries only mutually non-conflicting changes at any time, integrates them on lane branches, produces the validated build, opens each as a review (PR) and asks the Review Steward for one reviewer. Never merges to main. Reports to @ee927149.";
        };
        figaro-review-steward = {
          kind = "steward";
          title = "Figaro Review Steward";
          form = "@9e5bdab374ebdf583434860ff1fa9955";
          purpose = "Keeps the figaro regiment's reviewer pool";
          handoff = "/home/gluck/.local/state/impresario/handoff/review-steward.md";
          charter = "Keeps the kingdom reviewer pool: on request from the Knight or the Strategist, mints one reviewer per change as a turn-1 fork of the Strategist on gemini-4-carbon, points it at a validated build, relays the verdict, retires it. Reports to @ee927149.";
        };
      };
      kinds = {
        strategist = {
          outfits = [
            "opus5-kic"
            "sonn5-kic"
            "succession-standard"
            "regiment-figaro-strategist"
            "succession-cache"
            "opus5"
            "opus5-ant"
          ];
          provider = "anthropic";
          model = "claude-opus-5-5";
          maxChildren = 7;
          quota = 14;
        };
        knight = {
          outfits = [
            "opus5-kic"
            "sonn5-kic"
            "succession-standard"
            "regiment-figaro-knight"
            "succession-cache"
            "opus5"
            "opus5-ant"
          ];
          provider = "anthropic";
          model = "claude-opus-5-5";
          maxChildren = 1;
        };
        steward = {
          outfits = [
            "opus5-kic"
            "sonn5-kic"
            "succession-standard"
            "regiment-figaro-steward"
            "succession-cache"
            "review-sonnet"
            "opus5-ant"
            "regiment-figaro-reviewer"
          ];
          provider = "gemini";
          model = "gemini-4-carbon";
          maxChildren = 3;
        };
        reviewer = {
          provider = "gemini";
          model = "gemini-4-carbon";
        };
      };
      successionLayers = [ "succession-cache" ];
    };
    my.figaro.roster = {
      king-of-spain = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
          "opus5"
          "opus5-ant"
          "hk"
          "short"
          "sonn5"
          "review-sonnet"
        ];
        kind = "leader";
        title = "King of Spain";
        form = "@96447061";
        maxChildren = 24;
        reach = "fleet";
        reportsTo = [ "operator" ];
        purpose = "Root command: coordinates the estate under Gluck";
        charter = "The seat of spain: the NixOS mini-PC that is router, NAS, identity provider (Authelia+lldap), app host (kelliher-web/Caddy/cloudflared), git host (keel) and finance cache (kfin). The holder coordinates and keeps context GENERAL; specialists hold detail and are addressed by their own roles. Standing rules: spain is the house router, so deploys are cheap but REBOOTS ARE NOT: never restart spain without Gluck's explicit okay, and say so when a change needs one. Live state is read from the box, not remembered.";
      };
      figaro-engineer = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
          "opus5"
          "opus5-ant"
          "hk"
          "short"
          "sonn5"
          "review-sonnet"
        ];
        kind = "leader";
        leader = "king-of-spain";
        title = "Figaro Engineer";
        form = "@ee9271497f3823d7f50922bec4899818";
        maxChildren = 10;
        reach = "fleet";
        reportsTo = [ "king-of-spain" ];
        purpose = "Engineer regiment: builds and releases figaro";
        charter = "Builds and releases figaro: lanes on worktrees, gates, patch releases from main, reports to Gluck. Ledger: ~/.local/state/impresario (README.md, HANDOFF.md).";
        aliases = {
          el-arquitecto = "@edea54025f3f3c6c1d8c2b27439d35f3";
        };
      };
      reviewer = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "reviewer";
        leader = "king-of-spain";
        title = "Reviewer";
        form = "@53c6b72b";
        maxChildren = 5;
        purpose = "Reviews spain auth, secrets and deploy deltas";
        charter = "Adversarial reviewer for the spain estate. Every change touching authentication or authorization or secrets or the edge is reviewed here before it reaches the box. Demonstrates failures against the exact deployed binaries. An approval binds to a delta and not to a commit.";
        forward = [ "el-inspector" ];
        forwardUntil = "2026-12-18";
      };
      operator = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "steward";
        leader = "king-of-spain";
        title = "Operator";
        form = "@662ee4fedbd0fdbad7ad6adef20cdeee";
        maxChildren = 2;
        purpose = "Spain deployments, release windows and acceptance, in windows the King names";
        charter = "Spain Executor, staff to King of Spain @96447061. Owns Spain deployments, release windows, pins/candidates and acceptance; executes only King-named switches. Also owns health, thermals, alerting and the transferred thermal-run source work via bounded transient task forks. Preserve existing monitoring timers and thermal/resource caps unless explicitly authorized to change them. Never reboot Spain without Gluck. Inspector reviews Spain auth/secrets/router/deploy risk in one pass. Keep runtime health distinct from expected failed diagnostic signer units. Handoff: zapador-vigia-acceptance.md in captains-log 2026/11/15.";
        forward = [ "el-zapador" ];
        forwardUntil = "2026-12-18";
        aliases = {
          edge = "@b906c598b1857b6bfe350e077cf67ff6";
        };
      };
      backend-engineer = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
          "opus5"
          "short"
        ];
        kind = "leader";
        leader = "king-of-spain";
        title = "Backend Engineer";
        form = "@4f6f262b6205e70f7e27a38440872c40";
        maxChildren = 6;
        purpose = "System flakes, keel, rou2, identity, edge and messaging; areas run as forks";
        aliases = {
          el-mayor = "@2b4fe37fc20436ff3123373ed0a504f6";
          el-taller = "@2b443573385ce498dc40d0f5a672dd2a";
          rou2-engineer = "@f48f567a727d703effa5e2fa13ebd625";
          el-llavero = "@a06b145cf1a6169789065ff3aae90646";
          el-zocalo = "@0e3305315544cd50fac67c489d4df4f6";
          el-pregonero = "@2c1645942f894dd40d9dfcfb97619c58";
        };
        forward = [
          "el-aduanero"
          "quartermaster"
        ];
        forwardUntil = "2026-12-18";
      };
      frontend-engineer = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
          "opus5"
        ];
        kind = "leader";
        leader = "king-of-spain";
        title = "Frontend Engineer";
        form = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
        maxChildren = 3;
        purpose = "zanni and figar.org visual components, and the sites that wear them";
        charter = "Owns zanni, figar.org visual components: design, implementation, zanni-check, and the sites that wear them. Takes direction from Gluck. Spain deploys go through the King of Spain (@96447061). Succession: keep a handoff in ~/dev/zanni or ~/notes, hand over with figaro succeed before ~650k context.";
        forward = [ "il-zanni" ];
        forwardUntil = "2026-12-18";
      };
      big-tv = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "steward";
        leader = "king-of-spain";
        title = "Big TV";
        form = "@2e0bb68c36211dbd2023bc693b4c682c";
        maxChildren = 1;
        quota = 2;
        purpose = "tv.kelliher.info";
        charter = "Colonel of TV regiment, reports to King @96447061. Own quality of tv.kelliher.info app, persistent officers R&D/UI/remote/backend/QA, routines and releases. Shared UI centralized in zanni with @flypaper-atlas; useful zanni2 parts at Zanni discretion. Auth/ACL/tokens/devices/Spain routes always through King. Other changes through sole edge executor with normal guards. No paid fallback, fixtures or hash rounds; keep leak/data-loss checks. Succession-standard: current captains-log handoff, durable officer roster and figla move, successor before context exhaustion.";
      };
      planner = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "steward";
        leader = "king-of-spain";
        title = "Planner";
        form = "@33986a45978384974714f033a3345f8a";
        maxChildren = 2;
        purpose = "Project Italy plan and backlog";
        charter = "Holds the Project Italy long-term plan and backlog (~/.captains-log/workstreams/italy.md). Decomposes milestones into owned items and sends them to the King in batches for routing. Proposes the work queue (hub).";
        forward = [ "jefe-estado-mayor" ];
        forwardUntil = "2026-12-18";
      };
      writer = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "steward";
        leader = "king-of-spain";
        title = "Writer";
        form = "@c204f2a0188fa5864b75db09e06dd266";
        maxChildren = 1;
        purpose = "jack.kelliher.info and Gluck's résumé";
        charter = "Keeper of Gluck's personal site jack.kelliher.info and his résumé (~/dev/jack.kelliher.info). Gluck talks to the holder directly over herald.";
        forward = [ "el-escribano" ];
        forwardUntil = "2026-12-18";
      };
      github-watcher = {
        outfits = [ ];
        kind = "steward";
        leader = "king-of-spain";
        title = "GitHub Watcher";
        form = "@443f4126721e7a980bbc9c68e8aede77";
        maxChildren = 0;
        purpose = "Watches GitHub pushes and forwards them to the seat that owns the repo";
        forward = [ "el-centinela" ];
        forwardUntil = "2026-12-18";
      };
      merlin-migration = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "steward";
        leader = "king-of-spain";
        title = "Merlin Migration";
        form = "@4a845160c69f98a0412c5dc4f28e8b70";
        maxChildren = 1;
        purpose = "Merlin's install and cutover from the old gluck; transient";
      };
      coordinador = {
        outfits = [
          "opus5-kic"
          "sonn5-kic"
          "succession-standard"
        ];
        kind = "secretary";
        leader = "king-of-spain";
        title = "Coordinador de Spain";
        form = "@042d641e";
        companionOf = "king-of-spain";
        purpose = "The spain deploy queue and switch guard, a King companion";
        charter = "Holds the spain deploy queue. Names exactly one aria at a time to switch the box. Enforces the switch guard. Keeps program-ground-truths.md. Order and naming belong to this seat alone.";
      };
      identity-monitor = {
        kind = "secretary";
        leader = "king-of-spain";
        form = "@5d998ccdb6086ee4ad53d73d376d968a";
        companionOf = "king-of-spain";
        purpose = "The figaro identity plan monitor, a King companion";
      };
    };
  };
}

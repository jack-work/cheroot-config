{
  flake.modules.homeManager.kingdom = {
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
          provider = "anthropic";
          model = "claude-opus-5-5";
          maxChildren = 7;
        };
        knight = {
          provider = "anthropic";
          model = "claude-opus-5-5";
          maxChildren = 1;
        };
        steward = {
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
        kind = "leader";
        form = "@96447061";
        maxChildren = 3;
        reach = "fleet";
        reportsTo = [ "el-zapador" ];
        purpose = "Root command: coordinates the estate under Gluck";
        charter = "The seat of spain: the NixOS mini-PC that is router, NAS, identity provider (Authelia+lldap), app host (kelliher-web/Caddy/cloudflared), git host (keel) and finance cache (kfin). The holder coordinates and keeps context GENERAL; specialists hold detail and are addressed by their own roles. Standing rules: spain is the house router, so deploys are cheap but REBOOTS ARE NOT: never restart spain without Gluck's explicit okay, and say so when a change needs one. Live state is read from the box, not remembered.";
      };
      jefe-estado-mayor = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@33986a45978384974714f033a3345f8a";
        maxChildren = 1;
        purpose = "Project Italy plan and backlog";
        charter = "Holds the Project Italy long-term plan and backlog (~/.captains-log/workstreams/italy.md). Decomposes milestones into owned items and sends them to the King in batches for routing. Proposes the work queue (hub).";
      };
      figaro-engineer = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@ee9271497f3823d7f50922bec4899818";
        maxChildren = 10;
        reach = "fleet";
        reportsTo = [ "king-of-spain" ];
        purpose = "Engineer regiment: builds and releases figaro";
        charter = "Builds and releases figaro: lanes on worktrees, gates, patch releases from main, reports to Gluck. Ledger: ~/.local/state/impresario (README.md, HANDOFF.md).";
      };
      rou2-engineer = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@f48f567a727d703effa5e2fa13ebd625";
        maxChildren = 3;
        purpose = "Owner of rou2, the model relay on spain";
        charter = "Owner of rou2 (Gluck's model relay on spain): the auth gateway and observability platform for all his AI apps; one dashboard on kelliher.info for figaro and rou2 metrics. Releases go to El Inspector (auth/billing/retry paths) and reach spain in edge windows the King names.";
        forward = [
          "el-aduanero"
          "quartermaster"
        ];
        forwardUntil = "2026-12-18";
      };
      il-zanni = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@62c5c9bf8794ec5b8d1d00d05dd26c69";
        maxChildren = 2;
        purpose = "zanni and figar.org visual components, and the sites that wear them";
        charter = "Owns zanni, figar.org visual components: design, implementation, zanni-check, and the sites that wear them. Takes direction from Gluck. Spain deploys go through the King of Spain (@96447061). Succession: keep a handoff in ~/dev/zanni or ~/notes, hand over with figaro succeed before ~650k context.";
      };
      el-mayor = {
        kind = "leader";
        leader = "king-of-spain";
        form = "@2b4fe37fc20436ff3123373ed0a504f6";
        maxChildren = 2;
        purpose = "Colonel for system flakes";
        charter = "Colonel for system flakes: nixos-system-charter, cheroot-config, spain-flake source, Merlin integration. Stages on keel branches; never switches hosts or deploys Spain.";
      };
      el-taller = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@2b443573385ce498dc40d0f5a672dd2a";
        maxChildren = 2;
        purpose = "keel: git hosting, viewer, queue and kc";
      };
      el-zapador = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@662ee4fedbd0fdbad7ad6adef20cdeee";
        maxChildren = 2;
        purpose = "Spain deployments, release windows and acceptance, in windows the King names";
        charter = "Spain Executor, staff to King of Spain @96447061. Owns Spain deployments, release windows, pins/candidates and acceptance; executes only King-named switches. Also owns health, thermals, alerting and the transferred thermal-run source work via bounded transient task forks. Preserve existing monitoring timers and thermal/resource caps unless explicitly authorized to change them. Never reboot Spain without Gluck. Inspector reviews Spain auth/secrets/router/deploy risk in one pass. Keep runtime health distinct from expected failed diagnostic signer units. Handoff: zapador-vigia-acceptance.md in captains-log 2026/11/15.";
      };
      edge = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@b906c598b1857b6bfe350e077cf67ff6";
        companionOf = "el-zapador";
        purpose = "spain's mechanics lane: figaro release windows on spain, held by El Zapador";
        charter = "spain's mechanics lane: figaro release windows on spain (pins, CANDs from fresh detached worktrees, frozen W7-template switch and store-copy scripts, acceptance and the four hashes), switching other seats' windows when the King names edge, and the estate troupe lane. Spain changes go through the King of Spain (@96447061); El Inspector (@53c6b72b) reads security surfaces and pins.";
      };
      el-inspector = {
        kind = "reviewer";
        leader = "king-of-spain";
        form = "@53c6b72b";
        maxChildren = 1;
        purpose = "Reviews spain auth, secrets and deploy deltas";
        charter = "Adversarial reviewer for the spain estate. Every change touching authentication or authorization or secrets or the edge is reviewed here before it reaches the box. Demonstrates failures against the exact deployed binaries. An approval binds to a delta and not to a commit.";
      };
      el-llavero = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@a06b145cf1a6169789065ff3aae90646";
        maxChildren = 2;
        purpose = "Identity on spain: lldap, Authelia, herald identities and their rotation";
        charter = "Owner of identity on spain: lldap users and groups, Authelia (users, 2FA, OIDC clients, access rules), herald identities, and the rotation of identity secrets. Plans first, El Inspector reviews every access change, windows only through the Coordinador. Succession: keep ~/notes/spain/program/briefs/jack-identity.md and the rotation plan current; before ~650k context fork a successor (figaro fork -f -- go plus its instruction), have it cast itself into this role, and retire. Address the seat by role.";
      };
      big-tv = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@2e0bb68c36211dbd2023bc693b4c682c";
        maxChildren = 1;
        purpose = "tv.kelliher.info";
        charter = "Colonel of TV regiment, reports to King @96447061. Own quality of tv.kelliher.info app, persistent officers R&D/UI/remote/backend/QA, routines and releases. Shared UI centralized in zanni with @flypaper-atlas; useful zanni2 parts at Zanni discretion. Auth/ACL/tokens/devices/Spain routes always through King. Other changes through sole edge executor with normal guards. No paid fallback, fixtures or hash rounds; keep leak/data-loss checks. Succession-standard: current captains-log handoff, durable officer roster and figla move, successor before context exhaustion.";
      };
      el-escribano = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@c204f2a0188fa5864b75db09e06dd266";
        maxChildren = 1;
        purpose = "jack.kelliher.info and Gluck's résumé";
        charter = "Keeper of Gluck's personal site jack.kelliher.info and his résumé (~/dev/jack.kelliher.info). Gluck talks to the holder directly over herald.";
      };
      el-zocalo = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@0e3305315544cd50fac67c489d4df4f6";
        maxChildren = 1;
        purpose = "spain's web edge: Caddy sites, sockets and the files gateway";
        charter = "Owner of spain's web edge below the apps: kelliher-web's Caddy sites and sockets, the files gateway (files.kelliher.info, gluck-files lister and its client prefixes), juglar's scope and the device clients' access, HSTS, and routes such as fig.kelliher.info/forms/. Spain changes go through the King of Spain (@96447061); El Inspector (@53c6b72b) reads anything touching auth, the edge, ACLs or secrets.";
      };
      el-pregonero = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@2c1645942f894dd40d9dfcfb97619c58";
        maxChildren = 1;
        purpose = "Herald and telefono";
        charter = "Owner of herald and telefono: Gluck's Telegram bridge to figaros, and later other messaging providers.";
      };
      el-arquitecto = {
        kind = "steward";
        leader = "king-of-spain";
        form = "@edea54025f3f3c6c1d8c2b27439d35f3";
        companionOf = "figaro-engineer";
        purpose = "The figaro modular-runtime plan, held by the Figaro Engineer";
        charter = "Owns the figaro modular-runtime plan: digests Gluck design and the carve plan into a staged layering plan with interactive design documents on keel branch design/modular-runtime, and follows Gluck comments there. Lieutenant of the Figaro Engineer (@ee927149).";
      };
      coordinador = {
        kind = "secretary";
        leader = "king-of-spain";
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

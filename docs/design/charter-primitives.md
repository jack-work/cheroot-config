# Charter primitives and rosters

Status: design for Gluck's review. Nothing here is built yet. Base: cheroot-config main 3bb3792.

## 1. Where the concepts live today

| File | Lines | What it holds | Problem |
|---|---|---|---|
| `charter/modules/figaro.nix` | 831 | the figaro aspect (package, credo, outfits, providers, skills), plus the role submodule (24 options), the regiment and kind submodules, alias expansion, title and house-field rendering, the apply manifest, seat grants, the roster files and figaro-apply-roles | one file is both the figaro install and the whole kingdom engine |
| `charter/lib/roster.nix` | 189 | roster validation, kinds list, companion rules, authority (grants) per seat, TOML rendering | named "roster" but holds seat rules |
| `charter/lib/regiment.nix` | 223 | regiment expansion into roster roles, regiment outfits, the agreement text | a second seat constructor beside the role submodule |
| `charter/lib/grants.nix` | 170 | scopes, child policy, quota derivation, verbs, reaches | fine as a primitive |
| `charter/lib/apply-roles.py` | 132 | the apply/check runner | fine |
| `charter/modules/roles/{desktop,laptop,wsl}.nix` | | home-manager host bundles, picked by `mkHost { roles = [...]; }` | "role" means a host bundle here and a figaro role form everywhere else |
| `desktop-system/modules/kingdom.nix` | 206 | gluck's kingdom: 1 regiment, 14 seats, 10 aliases and companions, the Sonnet outfits, fanout.when-full | a roster written in option plumbing |
| `desktop-system/modules/checks.nix`, `tests/kingdom-seats.py` | | the kingdom-seats check | reads charter internals by file name |

Overlap to remove:
- A seat can be declared three ways: `my.figaro.roster.<name>`, `my.figaro.regiments.<r>.seats.<s>`, or an entry in a seat's `aliases`. Each path rebuilds the same 24-key record by hand (`regiment.nix` `seatRole`, `figaro.nix` `aliasRoles`).
- `companionOf` and `aliases` are one idea spelled twice.
- `name`, `title`, `role-name`: a seat's key, its display name, and two form keys for that name.
- "role" is both a host bundle and a figaro role form.
- "charter" is both the flake and a seat's duty text.

## 2. Vocabulary

One word per concept, used for options, files, docs and form keys.

| Word | Means | Lives in |
|---|---|---|
| **role** | figaro's object: a form with `target-aria`. Has an exact id. The charter never mints one. | figaro daemon |
| **holder** | the aria a role's `target-aria` points at. Runtime only; the charter never names it. | figaro daemon |
| **seat** | one declared position: a role id, a kind, a leader, a limit, a duty. One seat binds one role. | consumer roster |
| **duty** | a seat's standing text, written to the role form's `charter` key. (Today's `charter` option.) | consumer roster |
| **kind** | a catalogue entry of seat defaults: figaro role kind, reach, provider/model, limit, allowed outfits. | charter primitives, extendable |
| **leader** | the seat a seat answers to. Forms the hierarchy. | consumer roster |
| **limit** | fan-out: `children` (max live children) and `quota`. Applied as `system.fanout.*`. | consumer roster, kind default |
| **alias** | an extra role held by a seat's holder: a routing alias (old name, no duty) or a companion (its own duty). Never carries a limit. | consumer roster, under its seat |
| **regiment** | a group of seats bound by an agreement (strategist, knight, steward, reviewers). Expands to seats. | consumer roster, via `mkRegiment` |
| **roster** | one consumer's tree of seats and regiments. | consumer flake, one file |
| **charter** | the shared flake of primitives only. Never a seat field. | `charter/` (later its own repo) |
| **profile** | a home-manager host bundle (today's `roles/desktop.nix`). | charter primitives |

Renames: `charter` option -> `duty`; `maxChildren`/`quota` -> `limit = { children; quota; }`; `companionOf` and `aliases` -> `aliases` on the seat; `title` stays, and `name`/`role-name` are only its rendering; `modules/roles/*` -> `modules/profiles/*`, `mkHost.roles` -> `mkHost.profiles`.

## 3. Primitive API

The charter exports `lib.kingdom` and one home-manager module, `kingdom`, with a single option `my.kingdom`. Consumers write the roster as data with constructors; the module renders outfits, the manifest, the roster files and the apply runner. `figaro.nix` keeps only the figaro install.

```nix
# charter/lib/kingdom.nix
{
  kinds = { leader = {...}; steward = {...}; reviewer = {...}; secretary = {...};
            strategist = {...}; knight = {...}; review-steward = {...}; };

  mkSeat = { role, kind, title ? null, duty ? null, purpose,
             leader ? "@root", limit ? kinds.${kind}.limit or null,
             reach ? kinds.${kind}.reach or "lineage", reportsTo ? [ ],
             outfits ? kinds.${kind}.outfits or null, aliases ? { },
             forward ? { }, fields ? { }, mode ? "check" }: { ... };

  alias = role: { inherit role; };                    # routing alias, no duty
  companion = role: duty: { inherit role duty; };     # its own duty, same holder

  mkRegiment = { leader, agreement, seats, kinds ? {} }: { ... };  # returns seats
}
```

Rules the constructors enforce at evaluation, before anything builds (moved out of `kingdom-seats.py` where they are value checks): exact role ids, unknown leader, leader cycles, an alias never declared as a seat, an alias never limited, quota >= children, forward names unique and dated, reserved form keys refused in `fields`.

`system.history` is owner-set, not charter-managed: form apply refuses it as a reserved key, so the King sets it on a form through the owner path and the charter never declares it. 39d8273 tried to declare it and was reverted.

`leader = "@root"` means the roster's root seat, so most seats need no leader line.

## 4. The real roster in the new form

```nix
# desktop-system/kingdom.nix (gluck's roster), abbreviated duties
{ inputs, ... }:
let k = inputs.charter.lib.kingdom; in
{
  flake.modules.homeManager.kingdom.my.kingdom = {
    root = "king-of-spain";
    whenFull = "If a fork or new is refused for fan-out quota, ...";

    seats = {
      king-of-spain = k.mkSeat {
        role = "@96447061"; kind = "leader"; title = "King of Spain";
        leader = null; reach = "fleet"; limit.children = 24; reportsTo = [ "operator" ];
        purpose = "Root command"; duty = ./duties/king.md;
        aliases = {
          coordinador = k.companion "@042d641e" ./duties/coordinador.md;
          identity-monitor = k.companion "@5d998ccdb6086ee4ad53d73d376d968a" null;
        };
      };
      figaro-engineer = k.mkSeat {
        role = "@ee9271497f3823d7f50922bec4899818"; kind = "leader"; title = "Figaro Engineer";
        reach = "fleet"; limit.children = 10; reportsTo = [ "king-of-spain" ];
        purpose = "Builds and releases figaro"; duty = ./duties/figaro-engineer.md;
        aliases.el-arquitecto = k.alias "@edea54025f3f3c6c1d8c2b27439d35f3";
      };
      reviewer = k.mkSeat { role = "@53c6b72b"; kind = "reviewer"; title = "Reviewer"; limit.children = 5;
        forward.el-inspector = "2026-12-18"; purpose = "..."; duty = ./duties/reviewer.md; };
      operator = k.mkSeat { role = "@662ee4fedbd0fdbad7ad6adef20cdeee"; kind = "steward"; title = "Operator";
        limit.children = 2; forward.el-zapador = "2026-12-18";
        aliases.edge = k.alias "@b906c598b1857b6bfe350e077cf67ff6"; purpose = "..."; };
      backend-engineer = k.mkSeat {
        role = "@4f6f262b6205e70f7e27a38440872c40"; kind = "leader"; title = "Backend Engineer";
        limit.children = 6; forward = { el-aduanero = "2026-12-18"; quartermaster = "2026-12-18"; };
        purpose = "...";
        aliases = {
          el-mayor = k.alias "@2b4fe37fc20436ff3123373ed0a504f6";
          el-taller = k.alias "@2b443573385ce498dc40d0f5a672dd2a";
          rou2-engineer = k.alias "@f48f567a727d703effa5e2fa13ebd625";
          el-llavero = k.alias "@a06b145cf1a6169789065ff3aae90646";
          el-zocalo = k.alias "@0e3305315544cd50fac67c489d4df4f6";
          el-pregonero = k.alias "@2c1645942f894dd40d9dfcfb97619c58";
        };
      };
      frontend-engineer = k.mkSeat { role = "@62c5c9bf8794ec5b8d1d00d05dd26c69"; kind = "leader";
        title = "Frontend Engineer"; limit.children = 3; forward.il-zanni = "2026-12-18"; purpose = "..."; };
      big-tv   = k.mkSeat { role = "@2e0bb68c36211dbd2023bc693b4c682c"; kind = "steward"; title = "Big TV"; limit = { children = 1; quota = 2; }; purpose = "..."; };
      planner  = k.mkSeat { role = "@33986a45978384974714f033a3345f8a"; kind = "steward"; title = "Planner"; limit.children = 2; forward.jefe-estado-mayor = "2026-12-18"; purpose = "..."; };
      writer   = k.mkSeat { role = "@c204f2a0188fa5864b75db09e06dd266"; kind = "steward"; title = "Writer"; limit.children = 1; forward.el-escribano = "2026-12-18"; purpose = "..."; };
      github-watcher   = k.mkSeat { role = "@443f4126721e7a980bbc9c68e8aede77"; kind = "steward"; title = "GitHub Watcher"; limit.children = 0; purpose = "..."; };
      merlin-migration = k.mkSeat { role = "@4a845160c69f98a0412c5dc4f28e8b70"; kind = "steward"; title = "Merlin Migration"; limit.children = 1; purpose = "..."; };
    }
    // k.mkRegiment {
      name = "figaro"; leader = "figaro-engineer";
      seats = {
        figaro-strategist     = { kind = "strategist";     role = "@9bf485c24507fe8484a001c18a1b84cc"; title = "Figaro Strategist"; duty = ./duties/strategist.md; };
        figaro-knight         = { kind = "knight";         role = "@d121c4041785b13c6261d6055f113f8d"; title = "Figaro Knight"; duty = ./duties/knight.md; };
        figaro-review-steward = { kind = "review-steward"; role = "@9e5bdab374ebdf583434860ff1fa9955"; title = "Figaro Review Steward"; duty = ./duties/review-steward.md; };
      };
    };
  };
}
```

About 80 lines against 206, with the duty texts moved to `duties/*.md`, so the long strings leave the Nix. The kinds catalogue carries what each regiment kind repeats today (provider, model, limit, outfits, succession layers).

## 5. Moves

1. `charter/lib/kingdom.nix`: kinds, `mkSeat`, `alias`, `companion`, `mkRegiment`, validation (from `roster.nix`, `regiment.nix`, the role submodule in `figaro.nix`). `grants.nix` stays as the authority primitive under it.
2. `charter/modules/kingdom.nix`: the `my.kingdom` option and all rendering (from `figaro.nix`: aliasRoles, rendered, manifest, seats JSON, outfit files, roster drv, figaro-apply-roles). `figaro.nix` shrinks to the figaro install.
3. Delete `my.figaro.roster`, `my.figaro.regiments`, `my.figaro.fanoutWhenFull`; `roster.nix` and `regiment.nix` fold into `lib/kingdom.nix`.
4. `charter/modules/roles/` -> `profiles/`, `mkHost.roles` -> `mkHost.profiles` (desktop-system hosts change one word each).
5. `desktop-system/modules/kingdom.nix` rewritten as section 4, duties to `desktop-system/duties/`.
6. `kingdom-seats.py` keeps only the rendered-file checks; the value rules move to evaluation (section 3).

Proof for step 2 of the brief: render gluck's roster files, manifest, seats JSON and every `role-*` outfit at 3bb3792 and after the move; the diff must be empty, and `figaro-apply-roles --check` (run by Gluck from his terminal) must print the same rows. Renaming `charter` -> `duty` changes no rendered byte, because the form key stays `charter`.

Breakage: the option names above. Outside desktop-system, spain-flake's unmerged charter-consumer branch declares one NixOS roster seat (`my.figaro.roster.king-xv`, no role id, with the reconcile hook); it moves to `my.kingdom` when that branch is rebased for its daytime window. Nothing live changes.

## 6. What other consumers write

Spain (its daemon holds no roles today): nothing on master. The charter-consumer branch's one placeholder seat either moves to `my.kingdom` or is dropped, since the seats live on gluck. If Spain later hosts seats, it imports `charter.homeModules.kingdom` (or a NixOS twin) and writes its own `my.kingdom` with its own root; the gluck roster is never imported.

Work cheroot: its own roster file, its own root seat and role ids, the same kinds; for example

```nix
my.kingdom = {
  root = "lead";
  seats.lead = k.mkSeat { role = "@<work id>"; kind = "leader"; title = "Lead"; leader = null; limit.children = 4; purpose = "..."; };
  seats.reviewer = k.mkSeat { role = "@<work id>"; kind = "reviewer"; limit.children = 2; purpose = "..."; };
};
```

## Open for Gluck

1. `duty` for the seat text, leaving `charter` to mean only the flake. Or keep `charter` for both.
2. `profile` for host bundles.
3. Companions (Coordinador, identity monitor) as aliases with a duty, rather than a separate concept.

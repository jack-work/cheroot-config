# nixos-system-charter: our prototype against nixos-wsl PR #1

Branches under comparison:

- design: `jack-work/nixos-wsl` `design/cheroot-config-layers`, `docs/design/nixos-system-charter.md` (PR #1, plan only)
- ours: `cheroot-config` `proposal/system-charter-split` (this branch) and `spain-flake` `proposal/charter-consumer`

This branch holds two flakes side by side:

| dir | role | inputs |
|---|---|---|
| `charter/` | the shared charter. Exports `modules.{nixos,homeManager}.<aspect>` and `lib`. Builds no host. | `github:` only: nixpkgs, flake-parts, import-tree, home-manager, figaro v0.71.0, hush v0.15.0 |
| `desktop-system/` | thin system flake: gluck, cheroot, cig, wsl (Home Manager), merlin (NixOS module + HM) | pins `charter` by rev with `follows` on all six shared inputs; adds cerrojo, llm-agents, merlin-figaro, and the two `git+ssh@spain` sources |

`spain-flake` `proposal/charter-consumer` pins the same charter rev and wires its box-local inputs into it.

The charter would be its own repo (`jack-work/nixos-system-charter`). It lives under `charter/` here so one push gives a reviewable diff and a `github:...?dir=charter` URL both consumers can lock today.

## 1. Concern slices versus OS layers

nixos-wsl splits by **layer**: `modules/` is NixOS, `home/` is Home Manager, `figaro/` is config data, `lib/` is helpers. One feature (figaro) lands in `modules/figaro/system-daemon.nix`, `home/figaro.nix`, `pkgs/figaro-config.nix`, `pkgs/figaro-roster-apply.nix` and `figaro/roster/*.toml`. Its slice-4 conversion made `modules/**` dendritic, but `home/` is still imported as a list and `mkHost` still names over 50 aspects in a fixed order because `nixosAspect` has to unwrap `deferredModule` to keep list-option order (gate 2313).

The charter splits by **concern**: one file owns every class of one feature.

| file | `nixos` aspect | `homeManager` aspect |
|---|---|---|
| `figaro.nix` | `my.figaro.mode = none\|system\|container`, credo, outfits, providers, typed roster, `managedRolesHook` unit | package (nullable), credo, outfits, providers, skills, roster, prompt hooks |
| `hush.nix` | `my.hush.agent`, `my.hush.cred` (per-node minter over `services.hush-cred`) | package (nullable), unlock policy, brave command |
| `keel.nix` | `kc` from `my.keel.src` | same, user scope |
| `captains-log.nix` | append-only `cl serve` unit | `cl`, skill, snapshot/analyse/health timers |
| `heavy.nix` | `heavy.slice` | user `heavy.slice` |
| `shell`, `tmux`, `git`, `go`, `editor`, `cli`, `prompt` | system half | user half |

What that buys:

- **A consumer picks a feature, not a layer.** Spain imports `(aspect "hush")` and sets `my.hush.cred`; the desktop imports `homeManager.hush`. Neither reads the other's half, and import-tree means no file list to keep in order.
- **Roster is typed, not a directory.** `my.figaro.roster.<name>` is a submodule with an enum `kind` and a `leader` regex; `lib/roster.nix` rejects bad entries at eval. nixos-wsl validates the same rules in Python at apply time.
- **The cost is honest:** a feature whose NixOS half reads the HM half (nixos-wsl's `captains-log-service` reads `home-manager.users.gluck.my.captainsLog.package`) has to be untangled into options. The charter does that: the service takes `package` or `src`, never a user's HM config.

## 2. `src` as a typed option, not a charter input

The blocker: cheroot-config 5f6c2d5 locks `keel` and `captains-log` as `git+ssh://git@spain/...`. Nix locks every input of every input, so any flake taking cheroot-config as an input must reach spain over ssh. gluk cannot (`captains-log/2026/11/15/cheroot-config-pin-block-finding.md`).

The charter takes neither:

```nix
my.keel.src = inputs.keel;                 # desktop-system/modules/estate.nix
my.captainsLog.src = inputs.captains-log;  # same
my.keel.src = keel;                        # spain-flake charter-wiring.nix
```

and asserts when the aspect is on and `src` is missing. Two gates enforce the rule:

- `charter/flake.nix` evaluates `lib/lock-gate.nix` against its own `flake.lock` before `mkFlake`: any node whose `locked.type` or `original.type` is not `github`, or any `git+ssh:`/`path:`/`file:`/`tarball` URL, throws. So does a second `nixpkgs` node. The `lock-github-only` check also proves the gate fires on a synthetic `git+ssh` lock, a `path:` lock and a dual-nixpkgs lock.
- `charter-zero-host-leaks` greps every charter `.nix` for node names, `kelliher.info`, tailnet IPs, `sopsFile` and `git+ssh://`. Helium's exit host, origin override and ports moved from charter defaults into `desktop-system/modules/estate.nix` because of it.

No dual locking: `desktop-system/flake.lock` has exactly one node each for `nixpkgs`, `home-manager`, `import-tree`, `hush` (`desktop-hosts-eval` counts them), because the charter input `follows` all six. Spain makes `charter.figaro` follow its `figaro-daemon` and `charter.hush` follow its own `hush`, so the charter never brings a second copy of either into spain's closure.

A WSL system flake can now lock the charter from GitHub alone.

## 3. What stays out of headless closures

| input | where | why |
|---|---|---|
| `cerrojo` | `desktop-system` (`modules/desktop/idle-lock.nix`), added to `guiAspects` there | GUI lock; a headless node never evaluates it |
| `llm-agents` | `desktop-system` (`modules/muse-code.nix`), opt-in role per host | four inputs of its own (bun2nix, flake-parts, systems, treefmt-nix); off `coreAspects` entirely |
| `merlin-figaro` | `desktop-system` | one host's pin; the charter's `commander` aspect takes `package` as an option |
| `nixpkgs-2311` | nixos-wsl system flake (not ported) | glibc 2.38 for one band-work template; same rule: a system-local input, never charter |
| spain's ~30 `git+ssh` inputs | `spain-flake` | box-local by construction |

`muse-code` was in cheroot-config's `coreAspects`, so even `gluck@wsl` evaluated `llm-agents`. It is now a role every desktop host names explicitly; package sets are unchanged (`tests/legacy-eval.nix`).

## 4. D-equal and lock-bump gates across systems

nixos-wsl's plan: the first system-flake commit proves every node's `nixosConfigurations.<node>` drvPath identical before and after; afterwards a charter landing makes the gate-runner open one lock-bump change per system.

What this prototype measures:

| system | gate | result |
|---|---|---|
| desktop | `tests/legacy-eval.nix` vs baseline 5f6c2d5 | package set, platform flags, shell aliases and git identity equal for gluck@gluck, marlowe@cheroot, gluck@wsl |
| desktop | drvPath | **not equal**, on purpose: the charter pins figaro v0.71.0 and hush v0.15.0 (needed for `homeManagerModules` and `hush-cred`). A pure move would keep the old pins and must show D-equal; this branch bundles the bump |
| merlin | `tests/merlin-eval.nix` | every assertion from the original branch passes on the charter |
| spain | `charter-consumer-eval` | evaluates; drvPath differs from b96992c by design: `hush-chatgpt.nix` is replaced by the charter's `services.hush-cred`, the minter socket moves to `/run/hush-cred/cred.sock`, and `kc`, `cl serve`, `heavy.slice` and the roster unit are new |

For real adoption the order is:

1. **Move commit, pins frozen.** Charter pins = system's current pins. Gate: drvPath equality per host (HM `activationPackage`, NixOS `toplevel`). Any difference is a move bug.
2. **Behaviour commits, one per idea**, each with its own expected diff (`nix store diff-closures` plus `diff -rq` of the toplevel, per spain's five steps).
3. **Lock bumps.** A charter landing runs `nix flake update charter` in each system flake on a branch; each system's own checks gate it. Spain still needs a named window; desktop needs `home-manager switch`. One red system never blocks another, because each lock moves independently.

Spain's `secrets-are-encrypted` and `secret-inventory` checks stay where the secrets are. The charter carries no sops path to inventory.

## 5. Where we differ from the plan, and why

- **No `nixosConfigurations` in the charter.** Same as the plan. We add the stronger form: the charter exports `lib.mkHomeHostWith` and `lib.mkNixosHostWith` taking the consumer's `nixpkgs` and module set, so a host builder never closes over charter inputs.
- **Per-node cred is an option tree, not a file.** `my.hush.cred.{recipient,identityFile,instances,resolvers}`. Spain sets them; a WSL node would set its own. nixos-wsl's `band-cred-node` declares credentials inline in the module.
- **The roster hook is declarative but inert by default.** `managedRolesHook.enable` installs `figaro-roster-reconcile` and a oneshot unit; it does not run on switch. Rebuilds never create or cast roles, which keeps merlin's rule.
- **One repo or two.** The plan renames nixos-wsl to the charter (R1). Our evidence favours a fresh `jack-work/nixos-system-charter` seeded from this `charter/` dir: it is 43 module files, github-only already, and carries no WSL code to strip.

## 6. Open

- `figaro` in spain-flake is still a `git+ssh` source for the figar.org installers; only `figaro-daemon` feeds the charter.
- `captains-log` is private on GitHub. Mirroring it public (or a deploy token) would let the desktop drop `git+ssh` too.
- `spain-flake` tag inputs need `allRefs=1` on this nix (2.35) to fetch an annotated tag rev; the consumer branch carries that fix to its lock.
- Not built: no toplevel realisation, no switch, no VM test.

## Measured, 2026-11-16 (charter 1bc319e)

| target | before | after |
|---|---|---|
| gluck@gluck | `fdjn7cg0...-home-manager-generation.drv` (5f6c2d5) | `y17b7cgb...-home-manager-generation.drv` |
| marlowe@cheroot | `cnvg0cql...` | `fnhpmr9j...` |
| gluck@wsl | `pdnrlgmy...` | `lcym3wlj...` |
| cig@gluck | | `36azv3i5...` |
| jack@merlin (HM) | | `pr4iiv48...` |
| merlin (NixOS, test fs) | | `d3ncdah4...-nixos-system-merlin` |
| spain toplevel | `vh4k9xba...-nixos-system-spain` (b96992c) | `9j4glm8i...-nixos-system-spain` |

Checks green: `charter#checks.{lock-github-only,charter-zero-host-leaks,charter-eval-aspects}`, `desktop-system#checks.desktop-hosts-eval`, `desktop-system/tests/{legacy,merlin}-eval.nix`, `spain-flake#checks.charter-consumer-eval`.

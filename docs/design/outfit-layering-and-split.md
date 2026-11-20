# Outfit layering, the root/derivation split, and a Merlin test: plan

Status: plan for Gluck's approval. No code until he approves. Companion to `charter-primitives.md`.

## 1. Delivery per consumer

figaro reads one outfit directory today (`~/.config/figaro/outfits`). The plan needs figaro to read an ordered list of roots, lowest first, where a later root wins by outfit name (the Figaro Engineer is sizing it, see section 4).

| Consumer | Managed set (from the charter and the consumer flake, not editable) | User overlay (editable, wins by name) |
|---|---|---|
| gluck (home-manager) | `~/.local/share/figaro/outfits`, home-manager store symlinks, read-only by construction | `~/.config/figaro/outfits`, plain files. Home-manager may also place overlay files here (`my.figaro.overlay`), and Gluck edits the rest at runtime |
| merlin (NixOS) | `/etc/figaro/outfits`, from `environment.etc`, root-owned, changed only by a sudo rebuild | `~jack/.config/figaro/outfits` |
| cheroot, wsl, cig | as gluck | as gluck |

Why a managed root and not a writable copy or an out-of-store symlink: a copy can be edited and then silently overwritten by the next switch; an out-of-store symlink makes the managed files editable through the repo. A separate read-only root keeps the managed set unedited and the overlay plainly the user's.

The `role-*`, `regiment-*` outfits the kingdom renders are managed. figaro must refuse an overlay that shadows a managed outfit's protected keys (charter, `system.fanout`, `system.grants`), or at least show it in `figaro state outfit --tree`.

## 2. Root versus derivations

| Stays in `charter/` (primitives) | Moves to the consumer (desktop-system, later spain, work cheroot) |
|---|---|
| the outfit option and its rendering into a managed root, for home-manager and NixOS | gluck's own outfits: `base/house`, `core`, `via/*`, `model/*`, `policy/succession-*`, `decide/*`, `misc/*`, `default*` (today hand files in `~/.config/figaro/outfits`) |
| the kingdom primitives and their outfit rendering (`charter-primitives.md`) | the roster (`kingdom.nix`) and its duties |
| figaro, hush, keel, captains-log aspects | `profiles/desktop`, `laptop`, `wsl` (today `charter/modules/roles/*`): everything host-shaped |
| `mkHomeHostWith`, `mkNixosHostWith` | host files, estate values (`estate.nix`) |

## 3. Split steps

1. figaro: ordered outfit roots, overlay wins by name, provenance in `--tree`, protected keys guarded, `--refresh` sees all roots. (Engineer; gate for everything below.)
2. charter: `my.figaro.outfits` renders into the managed root (home-manager: `xdg.dataFile`; NixOS: `environment.etc`), and writes the root list into figaro's config. `my.figaro.overlay` for home-manager overlay files. Check: a fixture outfit resolves from the managed root, an overlay of the same name wins, the store files are read-only.
3. desktop-system: gluck's hand outfits become `my.figaro.outfits` in the consumer, byte for byte. Proof: `figaro state outfit --tree <name>` resolves identically for every outfit before and after. The hand files then leave `~/.config/figaro/outfits` (Gluck deletes them; the overlay starts empty).
4. charter primitives refactor (`charter-primitives.md`), and `roles/*` move to desktop-system as `profiles/*`.
5. merlin: NixOS figaro aspect in house mode, owner `jack`, managed root `/etc/figaro/outfits`, `importFrom = /home/jack/.local/state/figaro-merlin` when the store moves over.

Each step is one branch with its own gate and a Gluck look, landed in order. Steps 2 to 4 change no rendered byte for gluck except the outfit paths in step 2/3.

## 4. Merlin test, all moving parts

A NixOS VM test in desktop-system, `checks.merlin-house`, built from `nixosConfigurations.merlin` minus its hardware file, so it tests the real module set:

| Part | What the test proves |
|---|---|
| hush | the hush agent starts for `jack`, unlocks a test secret, and figaro reads a provider key through it (stub provider) |
| figaro house mode | `figaro.socket` and `figaro.service` as system user `figaro`, owner `jack`, `mode = house` |
| valet | a figaro of `jack`'s runs a bash tool through `jack`'s valet: the file it writes is owned by `jack`, inside a granted directory only |
| outfits | an outfit from `/etc/figaro/outfits` resolves; `jack` cannot write that root; an overlay outfit of the same name in `~jack/.config/figaro/outfits` wins; `--tree` shows both |
| roles apply | `figaro-apply-roles --check` against a seeded test role form reports `unchanged`, and a holderless one `unseated` |
| tool start | a stub model's tool call completes (the peer-check trap we hit on spain) |

It reuses figaro's own `nix/tests/house-mode.nix` stub model. The outfit rows wait for step 1; the rest can run now on v0.76.1, so the test lands first with those rows and grows the outfit rows when figaro ships roots.

Then the real box: Gluck's trial boot of Merlin, with `merlin-cutover-checklist.md`.

## 5. Asked of Gluck

1. "Call it spain": what should be renamed spain? desktop-system, the kingdom, or the estate repo as a whole? Nothing is renamed until he says.
2. Approve the managed-root delivery (section 1) over a writable copy.
3. Approve the order in section 3, with the Merlin test landing before step 1.

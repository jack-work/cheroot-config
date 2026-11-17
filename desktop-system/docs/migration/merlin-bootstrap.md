# Merlin: root-only workstation bootstrap

This branch prepares a separate NixOS workstation, `merlin`, with login `jack`
(UID/GID 1000). It does not partition a disk, install an OS, switch the current
machine, copy a Figaro store or enroll Spain's fleet.

## What the flake owns

- `nixosModules.merlin`: account, NVIDIA/Niri, greetd, NetworkManager with iwd,
  firewall, PipeWire, and integrated Home Manager for JACK.
- No named `nixosConfigurations.merlin` is exported before actual hardware and
  boot configuration exist. The module is reusable without a failing install
  target appearing in whole-flake consumers.
- `homeConfigurations."jack@merlin"`: the same user configuration for isolated
  evaluation. Use integrated Home Manager on the installed NixOS host, not a
  second standalone activation that competes for the same files.
- `modules/commander.nix`: reusable user-scoped commander support.
- `modules/hosts/merlin.nix`: this machine's composition, including the known
  two-display layout. Shared feature definitions remain in aspects.

The commander is not a second Nix registry. Nix installs a package, configuration
and one user service; Figaro owns the role form, its binding and conversations.
No rebuild runs `new`, `cast`, `bind` or a proposed formation reconciler.

Figaro is independently pinned to v0.72.1, source
`fba39fc409d15c4fa504ac5bdcbd1d4c9ceb4abe`, through `merlin-figaro`. It is
the first release whose client finds the daemon through
`FIGARO_SYSTEMD_UNIT` (#60), which the commander exports. Existing
consumers keep the original `figaro` input and its lock. No package update or
running daemon upgrade on gluck is implied.

## Installer-owned hardware and storage

Gluck owns the partitioning and installation session. The previous migration
proposal's backup, old-boot preservation and final-growth decision still apply.
Free space inside Btrfs is not an unallocated partition, and a tail installation
cannot later grow backwards into a removed leading partition.

On the installer, generate hardware configuration from the actual mounted
candidate. Review its device identities, mounts, filesystems, encryption and
swap before importing it. Keep raw NixOS hardware modules outside `modules/`,
since import-tree treats every `.nix` there as a flake-parts module. An example
placement is `hardware/merlin/hardware-configuration.nix` and
`hardware/merlin/boot.nix`. No example UUID, partition number or boot target is
supplied here.

Once those real files exist, add this declaration inside
`modules/hosts/merlin.nix` to create the named installation target:

```nix
flake.nixosConfigurations.merlin = inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    config.flake.nixosModules.merlin
    ../../hardware/merlin/hardware-configuration.nix
    ../../hardware/merlin/boot.nix
  ];
};
```

Until then, the test constructs the module without hardware locally and checks
that it fails exactly these standard NixOS assertions:

```text
The ‘fileSystems’ option does not specify your root file system.
You must set the option ‘boot.loader.grub.devices’ or 'boot.loader.grub.mirroredBoots' to make the system bootable.
```

These refusals are intentional; the GRUB message is the unconfigured NixOS
default, not a decision to install GRUB. Choose the reviewed bootloader and
its target explicitly. Do not add fake root devices just to make a build pass.
Re-evaluate the final complete configuration, build it under the agreed resource
limits, and review the installation run sheet before installing.

The account has no password, SSH key or copied credentials declared. Gluck must
set JACK's login password through the installer before expecting to log in.
JACK's UID/GID 1000 must be confirmed free in the target. Password values never
belong in this flake. Initial hibernation services are disabled; no disk-backed
swap or resume device is guessed.

## One independent daemon

JACK's user service is `figaro-commander.service`, using the same pinned package
as the CLI. The NixOS `services.figaro` system daemon is explicitly disabled.
Do not add a second autospawner or enable both owners.

| State | Location |
|---|---|
| Configuration | `/home/jack/.config/figaro-merlin` |
| Durable store | `/home/jack/.local/state/figaro-merlin` |
| Disposable cache | `/home/jack/.cache/figaro-merlin` |
| Runtime sockets | `$XDG_RUNTIME_DIR/figaro-merlin` |

The service and login environment use matching `FIGARO_*` directories and
`FIGARO_NO_SELF_SPAWN=1`. The rendered shell assignment is exactly
`export FIGARO_RUNTIME_DIR="${XDG_RUNTIME_DIR}/figaro-merlin"`, so it expands
at login; the unit uses `%t/figaro-merlin`. The runtime fixture executes that
rendered assignment with two different UIDs and compares it to the expanded
unit path. The service drops an inherited `FIGARO_ARIA`.
`programs.figaro.restartOnSwitch` is false. Home Manager service switching is
`suggest`, so a switch also cannot restart this daemon indirectly through a
changed unit. At the pinned source, `internal/config/config.go:25-27` reads
`default_outfit`; the generated value `root` therefore selects
`outfits/root.toml`. `internal/config/outfit_files.go:12-41` indexes that file
by basename, while `internal/outfit/outfit.go:298-305,337-395` decodes arbitrary
TOML keys, preserves nested `system.*` fields and resolves
`skills = { dirName = "skills" }` relative to the explicit config directory.
Bundled skills load after the declared skills and win by name.

The explicit directory environment names are implemented by
`internal/config/config.go:832-841` (`FIGARO_CONFIG_DIR`) and
`internal/boot/boot.go:144-180` (`FIGARO_STATE_DIR`, `FIGARO_CACHE_DIR`,
`FIGARO_RUNTIME_DIR`). `internal/cli/angelus_client.go:48-50` refuses self-spawn
when `FIGARO_NO_SELF_SPAWN` is set. `cmd/figaro/main.go:24` recognizes
`--angelus`; the same entrypoint is used by the shipped `nix/module.nix`.
These are source checks at the exact pin, not a claim that daemon startup was
run by this branch.

New units are wanted by the user's `default.target`; after a
first activation in an already-running user session, explicitly reload the
user manager and start the service. Later upgrades or restarts are separate
operator decisions.

From JACK's fresh login, after configuration installation:

```sh
systemctl --user daemon-reload
systemctl --user start figaro-commander.service
systemctl --user status figaro-commander.service
```

These are future Merlin operator commands, not actions performed on gluck by
this branch. Confirm the runtime directory is Merlin's before using any Figaro
CLI. Do not carry an old `FIGARO_ARIA` environment value into the new session.
No linger setting is added, so the daemon follows JACK's user-manager lifetime.

## Create the initial root exactly once

The shipped primitives do not implement an atomic/idempotent root ensure.
`new` always creates a new occupant, and `new -CO` can partially succeed.
The first creation is therefore explicit and operator-owned, not an activation
hook. Rebuilding a host must not repeat it.

The root outfit names only `rou2` and `chatgpt-personal/gpt-6.1-sol` by default.
No provider file or credential is supplied, and no paid fallback is declared.
The confirmed design uses Spain's existing rou2 gateway with a distinct Merlin
client grant. Spain remains the sole upstream ChatGPT minter; Merlin must not
start a second OAuth or refresh chain. The endpoint, credential helper and
per-client grant contract are still being provided by the gateway owners.
No unverified provider keys or helper invocation is invented here. Declare only
confirmed nonsecret settings; Gluck enters the client secret locally, outside
Nix and model-visible commands. Root inference is not ready until Merlin's
client enrollment and an authenticated subscription proof succeed.

The pending native service-token contract has been source-checked at the same
Figaro pin. The public gateway is `https://rou2.kelliher.info/v1`; the explicit
token URL is `https://auth.kelliher.info/api/oidc/token`, with no issuer discovery
required. The service-token entry and client ID are `merlin-rou2`, with
`grant = client_credentials`, `auth_method = client_secret_basic` and
`secret_credential = merlin-rou2-client-secret`. These are pending enrollment
metadata, not provisioned grants. The provider would use preset `gateway`, its
named service token, Responses routing,
no replay and omitted `max_output_tokens`. The canonical native exchange is
`client_secret_basic`, with the explicit singleton audience
`https://rou2.kelliher.info` and `scopes = []`; the older post/implicit-audience
hush fallback is superseded.

The proposed local source file is
`/home/jack/.local/share/figaro-secrets/merlin-rou2-client-secret`. A future
operator-provisioned unit would load it under bare credential ID
`merlin-rou2-client-secret`, and the native resolver reads that ID beneath
`CREDENTIALS_DIRECTORY`. This branch does not create or read that file.
King still owns the Llavero source packet, Inspector review and a separately
approved deployment. Authelia registration, rou2 public-listener/ChatGPT
admission and operator secret entry remain prerequisites. No active provider
file, service-token stanza or `LoadCredential` is installed here, and an existing
unrelated grant is not permission to use ChatGPT.

The default is an explicit destination name, not evidence that it is reachable
or authenticated. Methods are initially disabled so there is no undeclared
secondary model route; enabling them requires a reviewed subscription-backed
decision route.

After confirming the intended provider setup and that no root already exists,
run these two separate commands without a prompt. Preserve each JSON receipt
before proceeding. If either fails, inspect the existing result rather than
rerunning a mint blindly.

```sh
figaro form new -O root-role -j
figaro new -C @RETURNED_FORM_ID -O root -j
```

The first receipt's `form_id` is already `@`-prefixed. Substitute that exact value
for `@RETURNED_FORM_ID`; do not add another `@`. The second receipt contains the
new `aria_id`. No model turn is requested by these commands. The resulting
Merlin role and holder are distinct from Spain's King.

Record those exact IDs once in
`$FIGARO_STATE_DIR/root-identity.json`, using private permissions and a
no-clobber write. Its shape is:

```json
{"role":"@<32 hex digits>","holder":"<32 hex digits>"}
```

Then run:

```sh
figaro-root-check
figaro listen @RETURNED_FORM_ID
```

`figaro-root-check` reads the recorded identity, checks the live role's
`target-aria` and verifies that the exact recorded occupant still exists as
idle, active or dormant. It also checks `reaped_at` and `retired_at`: a reaped
row can still report `state: dormant`. It refuses missing, malformed, reaped,
retired or mismatched state. It never creates or rebinds anything. Activation
repeats this read-only check only when the daemon is already running and an
identity file exists; otherwise it announces that verification or first creation
is deferred.

The JSON contract was checked against the pinned source, not invented for the
fixture: `internal/cli/form.go:202-219` encodes the form snapshot directly,
`api/form/form.go:499` emits that snapshot as a nested object, and the role's
binding is its top-level `target-aria`. `internal/cli/status.go:22-59` encodes
the conversation row through `displayed`, whose embedded RPC fields are kept
by `internal/cli/aria_name.go:112-119`. `api/rpc/session.go:8-44` defines `id`,
`state`, `retired_at` and `reaped_at`. Dormant rows are constructed separately
from those lifetime markers in `internal/angelus/list_handlers.go:93`.

The file is an expected-identity receipt, not the authority for role binding.
If an explicit later succession changes the holder, verify the runtime result
and update the receipt deliberately. A mismatch is not permission to mint a
replacement. Do not place the mutable Figaro store or private receipts in git.

## Desktop acceptance and remaining work

This is a setup base, not a claim that physical daily driving passed. From a
TTY, confirm the shell and terminal first. Then test the actual RTX 3070
renderer, both displays, Niri login/logout/lock, portals, audio, networking and
representative project builds. A VM or Nix evaluation cannot prove the GPU,
monitor layout, suspend/resume or browser integration.

The base carries the shared Niri, terminal, notification, launcher, bar, fonts
and editor aspects. NetworkManager is the network owner; iwd is its Wi-Fi
backend, matching the `iwctl` bar dependency. The preflight search includes
NixOS's system package directory as well as the user profile.

Helium and 1Password are not enabled in this first slice: the existing Helium
aspect still assumes `/usr/bin/xdg-mime`, `/opt/1Password` and an Arch-supplied
browser. Those package/integration choices require their own checked port.
There is no silent browser substitution. The custom Kanagawa cursor's old
pacman-only package also remains a visual acceptance gap. Do not describe this
base as full daily-driving acceptance until those are resolved.

No Spain formation, live store, browser profile, Tailscale identity, OAuth
chain or service dataset is imported. Spain's King remains its coordinator.
The separate Merlin root can troubleshoot the candidate after its subscription
route is provisioned. Moving the main interactive store remains a different
cold-backup and single-writer cutover decision.

## Lightweight checks

```sh
bash tests/figaro-root-check.sh
python3 tests/commander-runtime.py
nix eval --impure --option allow-import-from-derivation false \
  --json --file tests/merlin-eval.nix
nix eval --impure --option allow-import-from-derivation false \
  --json --file tests/legacy-eval.nix
```

The shell test uses a fake CLI and temporary identity file, checking that a
valid binding passes and mismatches/invalid state never invoke creation or
binding. The Nix tests check the host and compare existing consumers to the
immutable starting revision `5f6c2d5dd19ee7b7653fa5717f2a186897b3189c`, without
realizing packages or switching services. On this branch, all three legacy
consumer derivation identities match the baseline exactly:

| Consumer | Before and after derivation |
|---|---|
| gluck@gluck | `/nix/store/fdjn7cg0yk8mz2f5f7yzl0232y0ss59h-home-manager-generation.drv` |
| marlowe@cheroot | `/nix/store/cnvg0cqlkg01a667nnimqj8y6aipjx6d-home-manager-generation.drv` |
| gluck@wsl | `/nix/store/pdnrlgmyvbnd4kpnl7bbf2bvljfkd1qy-home-manager-generation.drv` |

Package names, platform flags, preflight script bytes and shell aliases also
match. The rofi package rename is only evaluated on a Nix-owned desktop, and
the system preflight PATH addition is conditional on that same flag. Existing
Arch/WSL consumers keep their old behavior and the original Figaro pin.

The full Merlin Home Manager derivation evaluates, with the new Figaro pin and
one user daemon. The test-local NixOS module evaluation reports only its two
intended missing hardware assertions, reproduced above; no incomplete named
installation target is exported. Full builds, VM boot and hardware acceptance
are separate gates, not implied by these evaluation tests.

---
name: merlin-setup
description: Merlin's root-only workstation bootstrap, desktop checks, and runtime ownership.
---

# Merlin setup

This is an independent Merlin store under JACK. It is not Spain's King and
must not import Spain's roles, conversation store, provider secrets or workers.

The NixOS host owns accounts, GPU/kernel, greeter, networking and system services.
Home Manager owns desktop files, the pinned Figaro client, outfits and the
single figaro-commander user service. Do not enable services.figaro as well.

Root identity is recorded in FIGARO_STATE_DIR/root-identity.json. The runtime
role binding is authoritative. Run figaro-root-check to verify it. Never mint a
replacement because a check fails; preserve the store and investigate with Gluck.
Rebuilds install configuration but do not create, bind, cast or reconcile roles.

Start from a working TTY and terminal. Check the real NVIDIA renderer, both
monitors, Niri login/logout/lock, sound, networking and the selected browser.
A Nix evaluation is not physical GPU, display or login acceptance. Helium and
1Password provisioning require their separately reviewed package/integration
work; never substitute another browser silently or copy live login databases.

The first model prompt waits until Gluck provisions a distinct Merlin client
grant to Spain's existing rou2 gateway and verifies authenticated subscription
use. Spain remains the sole upstream ChatGPT minter; never start a second
OAuth or refresh chain on Merlin. Do not fall back to a paid provider. No
credential value belongs in Nix or a model-visible command. No Spain-store
migration or cold cutover is implied.

# cheroot-config

Home-manager configuration for two machines, in the
[dendritic pattern](https://github.com/mightyiam/dendritic): every `.nix` file
under `modules/` is a flake-parts module, auto-imported by
[`vic/import-tree`](https://github.com/vic/import-tree), and each file
implements **one feature across every configuration class it touches**.

| host | user | shape |
|---|---|---|
| `cheroot` | `marlowe` | ThinkPad X13 Gen 1, plain Arch, `laptop` role |
| `gluck` | `gluck` | desktop, CachyOS, `desktop` role |
| `wsl` | `gluck` | Windows box's Linux userland, `wsl` role, **no GUI aspects** |

```sh
nix develop
home-manager switch --flake .#marlowe@cheroot
home-manager switch --flake .#gluck@gluck -b bak   # first run on gluck: see below
home-manager switch --flake .#gluck@wsl
```

## Layout

```
flake.nix              inputs + one import-tree call. Nothing else.
lib/link-dir.nix       per-file linking helper (NOT a module — see below)
modules/
  options.nix          declares flake.modules and flake.homeConfigurations
  systems.nix  lib.nix  packages.nix
  base.nix             stateVersion, home-manager itself
  shell/core.nix       ← aliases + env declared ONCE, rendered into both shells
  shell/fish.nix       fish rendering
  shell/bash.nix       bash rendering
  figaro.nix           figaro across BOTH shells: prompt hooks + completions
  prompt.nix cli.nix editor.nix tmux.nix
  desktop/             niri waybar mako rofi alacritty, and session.nix
                       (the env a graphical session needs and nothing else does)
  roles/               laptop desktop wsl
  hosts/               cheroot gluck wsl
config/                verbatim config files, referenced by the modules
  fish/conf.d/         core fish modules — every host gets these
  fish/conf.d-graphical/  wayland repair; only hosts with a screen link it
```

## One flake, many machines

Everything independent of the machine lives in an **aspect** and is shared. A
host file declares only what is true of that machine. Three tiers, and the tier
is chosen by *audience*:

| Tier | Audience | Lives in | Examples |
|---|---|---|---|
| **Aspect** | every machine | `modules/**` | shell aliases, figaro, tmux, fonts |
| **Role** | a *class* of machine | `modules/roles/` | `laptop` — battery, backlight, trackpad |
| **Host** | exactly one machine | `modules/hosts/` | monitor layout, username, platform flags |

The rule: **if a second machine could ever want it, it is not host-specific.**
A thing used by two machines is a role, not a copy-paste.

Adding a machine is one small file:

```nix
{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "spain";
    aspects = config.flake.lib.coreAspects;   # headless: no GUI aspects at all
    roles   = [ ];
    settings = {
      my.platform.toolchainFromNix = true;
    };
  };
}
```

`mkHost` takes machines that need **less** as readily as more:
`aspects` defaults to everything, and a headless box narrows it to
`coreAspects`, dropping fonts, niri, waybar, mako, rofi and alacritty — not
merely unconfigured but never evaluated. `roles` layers extras on top, and
`settings` is an inline module with an audience of one.

**The `<user>@<hostname>` naming is load-bearing.** home-manager's CLI resolves
a bare `--flake .` by probing `$USER@$(hostname -f)`, `$USER@$(hostname)`, then
`$USER@$(hostname -s)`. Name the attribute correctly and every machine runs the
identical command, with no host argument to get wrong:

```sh
home-manager switch --flake .
```

Two mechanisms make the sharing work, and both are worth knowing:

- **`types.lines` merges by concatenation.** `my.niri.extra` can be appended by
  the host *and* the laptop role *and* any future aspect; they concatenate
  rather than conflict. That is why the shared niri config never needs to know
  which machines exist.
- **An option's `default` is not a definition.** `my.waybar.modulesRight`
  carries the desktop list as a default, so `roles/laptop.nix` simply *sets* it
  — no `mkForce`, no `mkIf`, and the base file never mentions laptops.

Finally: **import-tree ignores paths beginning with `_`.** Handy for scratch
files under `modules/`; confusing if you do it by accident and wonder why your
new host never appears.

## Machines with no screen (WSL, servers, containers)

`coreAspects` is the set that survives having no compositor, no GPU and no
window manager: **both shells, the prompt, the CLI tools, git, go, neovim and
its formatters, tmux, and figaro.** `guiAspects` is everything that assumes a
display. A headless host names only the first, and the second is never
evaluated — not installed-but-unused, *never built*.

```nix
flake.homeConfigurations = config.flake.lib.mkHost {
  user = "gluck"; host = "wsl";
  aspects = config.flake.lib.coreAspects;
  roles   = [ "wsl" ];
};
```

Proof, from the two generations built out of this one flake:

| | `gluck@gluck` | `gluck@wsl` |
|---|---|---|
| `~/.config/` | fish git go tmux **niri waybar mako rofi alacritty** | fish git go tmux |
| `fish/conf.d/12-wayland.fish` | yes | **absent** |
| `TERM` / `QT_QPA_PLATFORMTHEME` | set | **unset** |
| gcc, node, python3, tree-sitter | from pacman | from nix |

The seam is only honest if nothing display-shaped hides in a core aspect. Three
environment variables did, in `shell/core.nix`, and one of them — `TERM=alacritty` —
is an outright lie under Windows Terminal. They now live in
`modules/desktop/session.nix` (the `graphical` aspect), and `BROWSER`, which
names a *specific binary*, lives in the host file. **The test for anything in a
core aspect: would a machine with no screen want it?**

**Name the WSL machine, do not guess it.** home-manager resolves a bare
`--flake .` from the hostname, and WSL inherits the *Windows* PC name — mixed
case, and it changes when the PC is renamed. Pin it instead:

```sh
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[network]
hostname = wsl
generateHosts = true
EOF
```

then `wsl --shutdown` from PowerShell, reopen, and `home-manager switch --flake .`
finds `gluck@wsl` with no argument. Prefer the real name? Change the `host`
string in `modules/hosts/wsl.nix`; the attribute follows.

Clipboard needs nothing: the `clipcopy` fish function writes an OSC 52 escape to
the tty, which Windows Terminal honours — copying out of a WSL tmux pane into
Windows works with no `win32yank`, no `clip.exe` bridge and no X server.

## Both shells, one source

fish and bash are configured side by side. `shell/core.nix` declares aliases and
environment once; home-manager renders them into both. `starship`, `zoxide`,
`fzf` and `direnv` each enable both shells from a single `enable`.

Numbering is deliberately parallel so the two are readable together:

| | fish | bash |
|---|---|---|
| entry point | home-manager's `config.fish` | home-manager's `.bashrc` |
| modules | `~/.config/fish/conf.d/NN-*.fish` | `~/.bashrc.d/NN-*.sh` |
| env | `10-env` | `10-env` |
| brew | `15-brew` | `15-brew` |
| distro | `20-cachyos` | `20-distro` |
| PATH | `30-path` | `30-path` |
| conda | `50-conda` | `50-conda` |
| figaro prompt | `65-figaro-prompt` | `65-figaro-prompt` |
| fzf | `70-fzf` (fzf.fish plugin) | home-manager's fzf integration |

Neither shell is installed by nix: a login shell needs `/etc/shells` and a
stable path, so both come from pacman and nix only configures them.

## Things that will bite you

**Do not symlink a whole config directory.** `xdg.configFile."fish/conf.d".source
= ./dir` makes the directory a read-only store path, and fish writes
`fish_frozen_theme.fish` into `conf.d` (as does `fish_config` when saving a
theme). Use `lib/link-dir.nix`, which links each file individually and leaves the
directory real and writable.

**`lib/` is outside `modules/` on purpose.** import-tree imports *every* `.nix`
file beneath `modules/` as a flake-parts module, and a bare helper function is
not a module.

**`flake.modules` and `flake.homeConfigurations` must be declared** (see
`modules/options.nix`). flake-parts ships no declaration, so the second file to
touch either one fails with *"defined multiple times while it's expected to be
unique"*. Declaring them as `lazyAttrsOf deferredModule` / `lazyAttrsOf raw` is
what lets many files contribute to one aspect — the pattern depends on it.

**The figaro prompt hooks differ between shells, and must.** figaro resolves its
aria binding from its *immediate parent pid*. fish forks every pipeline member
itself; bash only skips the fork for a lone simple command substitution, so any
pipe or redirect *inside* the substitution silently loses the binding. Read the
header of `config/figaro/prompt.bash` before touching it.

**PATH must be assembled idempotently.** Plain prepends grow on every nested
shell — measured at +8 entries per level under the old fish config, and +2 under
bash from Homebrew's shellenv, which deduplicates for fish but not for bash.
fish uses `fish_add_path -gmp`; bash uses `path_prepend` in `30-path.sh`; brew is
guarded in `15-brew.sh`.

**Mutable directories stay mutable.** `~/.config/nvim` (lazy.nvim, mason) and
`~/.config/tmux/plugins` (tpm) are cloned by activation scripts, never linked.

**First switch on gluck needs `-b bak`.** Real files already exist at
`~/.config/fish`, `tmux.conf`, `alacritty.toml`, `starship.toml`; without the
backup flag home-manager refuses rather than clobbering.

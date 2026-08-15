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

```sh
nix develop
home-manager switch --flake .#marlowe@cheroot
home-manager switch --flake .#gluck@gluck -b bak   # first run on gluck: see below
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
  desktop/             niri waybar mako rofi alacritty
  roles/               laptop desktop
  hosts/               cheroot gluck
config/                verbatim config files, referenced by the modules
```

A **host is a list of aspect names**. `cheroot` and `gluck` differ by one role
name and their niri output blocks — nothing else.

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

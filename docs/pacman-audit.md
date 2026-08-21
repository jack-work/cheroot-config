# pacman → nix audit (gluck, 2026-08-15)

291 explicitly-installed pacman packages (1239 including dependencies).
Classified by whether nix *could* own them, and whether it *should*.

**The rule that governs all of this:** `~/.nix-profile/bin` precedes `/usr/bin`.
So installing something from nix that pacman also provides does not replace it —
it **shadows** it. Two copies on disk, the nix one winning silently, and pacman
upgrades that appear to do nothing. Every migration below is therefore a pair:
add to the flake, and `pacman -Rns` the old one.

Before removing anything, check nothing depends on it:

```sh
pacman -Qi <pkg> | grep -E 'Required By|Optional For'
```

---

## Required before the first switch

The flake already installs these; pacman's copies must go or they will be
shadowed:

```sh
sudo pacman -Rns github-cli
```

| package | why |
|---|---|
| `github-cli` | flake provides `gh`. Explicit, `Required By: None` — removes cleanly |

> **CORRECTION (2026-08-21).** This section originally read
> `pacman -Rns github-cli fzf`. **`fzf` cannot be removed**: it is not an
> explicit install but a dependency of `cachyos-fish-config` and
> `cachyos-zsh-config`. `-Rns` would refuse (or, if forced, take the cachyos
> config packages with it). Leave pacman's `fzf` in place and let nix's shadow
> it — 0.74.1 vs 0.74.2, and `fzf-tmux` ships in nix's build, so `prefix + B`
> works either way.
>
> The general rule stated above — *"every migration is a pair: add to the flake,
> and `pacman -Rns` the old one"* — **does not hold** for anything another
> package depends on. See "Shadowing is the norm, not the exception" below for
> the measured list.

> **Removing `github-cli` breaks git auth unless `.gitconfig` is fixed first.**
> Your hand-written `~/.gitconfig` set
> `helper = !/usr/bin/gh auth git-credential` — an **absolute path** into
> pacman's copy. `modules/git.nix` now declares the helper unqualified, so it
> resolves through PATH from any source. But see the next warning.

> **Delete `~/.gitconfig` by hand after switching.** home-manager writes to
> `$XDG_CONFIG_HOME/git/config`, and git reads *both* files, last value winning.
> `-b bak` will not back up `~/.gitconfig` because home-manager does not manage
> that path. Measured with both present, the **stale** `/usr/bin/gh` helper
> wins. Once: `mv ~/.gitconfig ~/.gitconfig.pre-nix`.

`lazygit` is **kept** for now: `snacks.nvim` binds `<leader>gg/gl/gf` to it and
`tree-bear.lua` calls `lazygit_worktree()`. `gitui` is additive until the nvim
config stops naming lazygit. nix's 0.63.1 will shadow pacman's 0.64.1 — a silent
minor downgrade, noted so it is not a surprise.

After switching, run `tmux kill-server` once. `run-shell` inherits the tmux
*server's* environment, captured at server start; a server predating the switch
has no `~/.nix-profile/bin` on PATH and will not find `fzf-tmux`.

---

## Shadowing is the norm, not the exception

*(Measured 2026-08-21 against the built generation, not predicted.)*

The built profile puts **54 binaries** on `PATH` ahead of `/usr/bin`. **19
pacman packages** are shadowed by them — not the two this document originally
implied:

| pacman package | shadowed binaries | removable? |
|---|---|---|
| `github-cli` | `gh` | **yes** — explicit, no dependents |
| `lazygit` | `lazygit` | yes, but see the 0.63.1 note above |
| `starship` `stylua` `tree` `zoxide` `neovim` `tmux` `man-db` | one each | yes — explicit, `Required By: None` |
| `fzf` | `fzf` `fzf-tmux` | **no** — `cachyos-fish-config`, `cachyos-zsh-config` |
| `bat` `eza` | `bat`, `exa`+`eza` | **no** — `cachyos-fish-config` |
| `fd` `ripgrep` | `fd`, `rg` | **no** — `hwdetect` |
| `jq` | `jq` | **no** — `scx-scheds`, `swaylock-fancy-git` |
| `fish` | `fish` `fish_indent` `fish_key_reader` | **no** — `cachyos-fish-config`, `fisher`, … |
| `git` | `git` + 6 helpers | **no** — `paru`, `yay`, `zed`, `lazygit` |
| `shared-mime-info` | `update-mime-database` | **no** — GTK 2/3/4, Qt 5/6, `colord` |
| `bash` | `bash` `sh` `bashbug` | **NEVER** — `base`, `pacman`, `systemd`, ~100 more |

**`bash` is the one to understand.** The flake installs it (`programs.bash`), so
it shadows pacman's. Applying this document's original "add + remove" rule to it
would take out `base`, `pacman` and `systemd`. Shadowing a package and retiring
it are *different decisions*, and only the first is automatic.

The good news, also measured: **shadowing is almost entirely version-neutral.**
Of the 16 shadowed pairs that report a version, 13 are byte-identical
(`bat` `fd` `jq` `rg` `starship` `tree` `zoxide` `nvim` `fish` `git` `stylua` …).
Only three differ, all trivially and all downgrades already known:

| tool | nix | pacman |
|---|---|---|
| `lazygit` | 0.63.1 | 0.64.1 |
| `gh` | 2.96.0 | 2.97.0 |
| `fzf` | 0.74.1 | 0.74.2 |

So the practical stance is: **let nix shadow, remove almost nothing.** Removal
buys disk and tidiness; it costs the risk above. `github-cli` is worth removing
because the stale `/usr/bin/gh` path in `~/.gitconfig` is a real trap. The rest
can sit.

## `man-db` deserves its own note

`man-db` appears in the shadow list without ever being asked for — home-manager's
`programs.man` is **enabled by default** and pulls it in. It is explicit in
pacman with no dependents, so it *looks* removable, but this document's Tier 3
rightly classes `man-db` as a core distro utility the system expects at a system
path. Recommended: leave pacman's installed, and consider
`programs.man.enable = false` if the nix copy ever misreads `/usr/share/man`.

---

## Candidates for home *management*, not just installation

Installing a package from nix is the small half. The larger half is
home-manager's `programs.*` / `services.*` modules, which manage the tool's
**configuration** as well. home-manager ships **350 program modules** and **162
service modules**; **39** of them match something you have installed via pacman:

| worth adopting | why |
|---|---|
| `programs.git` | **done** — `.gitconfig` was unmanaged and carried the `/usr/bin/gh` trap |
| `programs.gh` | **next up** — pairs with the `.gitconfig` credential-helper fix already in, and `github-cli` is the one package worth actually removing |
| `programs.go` | **done** — `~/.config/go/env` via `modules/go.nix`, `package = null` unless `toolchainFromNix`. Retired the hand-rolled `GOFLAGS` in `10-env` and the `go env GOPATH` shell-out in `30-path`. Open question left over: `~/.config/go/env` had `GOFLAGS=-mod=mod`, silently dead because the shell export beat it — only `-buildvcs=false` was carried forward. Reinstating `-mod=mod` is a decision, not a migration |
| `programs.btop`, `programs.htop` | small configs, currently hand-tuned or default |
| `programs.less`, `programs.ripgrep` | `LESS` opts, ripgrep ignore rules |
| `programs.fastfetch` | the shell greeting, currently distro default |
| `programs.bun`, `programs.uv`, `programs.npm` | registry/config files |
| `programs.aichat`, `programs.claude-code` | both already installed via pacman |

| deliberately NOT adopting | why |
|---|---|
| `programs.tmux` | generates tmux.conf from Nix attrs. Yours is 185 tuned lines incl. the 3.7b workaround — a rewrite with no gain |
| `programs.neovim` | config is a git clone that lazy.nvim and mason write into |
| `programs.waybar`, `services.mako`, `programs.alacritty`, `programs.rofi`, `programs.wofi`, `programs.swaylock`, `programs.wlogout` | we manage these as verbatim files, and enabling the module also installs a nix build of something that draws — see Tier 3 |
| `programs.chromium`, `programs.obs-studio`, `programs.vesktop`, `programs.freetube` | GPU / Electron; keep on pacman |

### The `package = null` trick

Many home-manager modules declare their package option **nullable**, which lets
you take the configuration management while leaving the *binary* to the distro —
exactly the right split on Arch. Verified nullable in this home-manager revision:

`git` `go` `btop` `less` `ripgrep` `fastfetch` `bun` `uv` `npm` `micro`
`aichat` `lazygit` `tmux`

```nix
programs.btop = {
  enable = true;
  package = null;      # pacman keeps the binary; nix owns ~/.config/btop
  settings = { ... };
};
```

This is the answer for anything heavy, or anything where the distro's version
should win.

---

## Tier 1 — safe to migrate, no system integration

Pure user-space CLI. All verified present in the pinned nixpkgs.

`btop` `htop` `glances` `duf` `tabiew` `pv` `sox` `dolt` `nmap` `rsync`
`unrar` `zip` `unzip` `wl-clipboard` `cbonsai` `aichat` `claude-code`
`fastfetch` `micro` `nano` `less` `diffutils` `man-pages` `plocate` `bind`
`ethtool` `tree` `wget`

Cost of moving: one `pacman -Rns` each. Benefit: pinned, reproducible, and
present on every host the flake touches.

## Tier 2 — migrate deliberately, version-sensitive

Toolchains and cloud CLIs. nix *has* them, but these are exactly the packages
where a silent version change hurts, and several are currently **newer** on
pacman.

`go` `rustup` `nodejs` `typescript` `bun` `uv` `python3` `pipx`
`terraform` `kubectl` `awscli2` `azure-cli` `postgresql` `docker-compose`
`docker-buildx` `podman-compose` `ghostscript`

Two live examples of why to be deliberate: nixpkgs `nodejs` is **24.18.0** while
pacman ships **26.4.0**; nixpkgs `gcc` is **15.3.0** against pacman's **16.2.1**.
This is the reason `my.platform.toolchainFromNix` defaults to **false** — see
`modules/platform.nix`.

## Tier 3 — keep on pacman (Arch), nix only on NixOS

**127 system packages**: kernel (`linux-cachyos*`), drivers (`nvidia-*`,
`mesa-*`, `vulkan-*`, `lib32-*`), firmware, bootloader (`grub`, `mkinitcpio`,
`efibootmgr`), filesystems (`btrfs-progs`, `lvm2`, `cryptsetup`, `snapper`),
services (`networkmanager`, `bluez`, `pipewire`, `wireplumber`, `cups`, `sddm`,
`tailscale`, `docker`), and all `cachyos-*` distro integration.

**51 packages that draw**: `niri` `waybar` `mako` `rofi` `alacritty` `swaybg`
`swaylock-*` `wofi` `wob` `firefox` `thorium-browser` `zen-browser` `gimp`
`obs-studio` `zoom` `zed` `rider` `1password` `xournalpp` …

These touch the GPU, and nixpkgs Mesa on a non-NixOS host is
[nixpkgs#9415](https://github.com/NixOS/nixpkgs/issues/9415) — open since 2015. A
nix-built compositor links nixpkgs Mesa against the Arch kernel driver and
renders in software, or not at all.

On **NixOS** every one of these flips to nix, via
`my.platform.desktopFromNix = true` for the graphical stack and
`modules/system/nixos.nix` for the system half.

## Fonts

`noto-fonts*` `ttf-*` `adobe-source-han-sans-*` `awesome-terminal-fonts` are all
in nixpkgs and could move. Low priority: they work, and fontconfig finds them
either way. The one that *had* to move already did — `GoMono Nerd Font` was
hand-installed under `~/.local/share/fonts` and owned by no package at all,
which is why cheroot rendered boxes. See `modules/fonts.nix`.

## Not in nixpkgs

`pkgfile` — Arch-specific (`pacman` file index). No nix equivalent, and none
wanted.

# Role: WSL — a Linux userland hosted by Windows.
#
# WHAT WSL IS, FOR THIS REPO'S PURPOSES: a machine with a full shell, a real
# kernel and no session of its own. There is no compositor, no login manager,
# no GPU worth claiming, and the terminal belongs to Windows. So a WSL host
# takes `coreAspects` — shells, prompt, cli, git, go, editor, tmux, figaro —
# and NONE of `guiAspects`. Not "installed but unused": never evaluated.
#
#     modules/hosts/wsl.nix
#       aspects = coreAspects
#       roles   = [ "wsl" ]
#
# This file owns what is true BECAUSE the machine is WSL, and nothing else.
{ lib, ... }:
{
  flake.modules.homeManager.wsl = {
    # A WSL distro image is minimal: Ubuntu ships gcc only if you ask, and the
    # Arch/NixOS images ship less. Nothing is in front of nix on PATH that
    # nix would shadow, so the shadowing hazard that makes this FALSE on gluck
    # (see modules/platform.nix) does not exist here. Neovim's treesitter and
    # mason need a compiler, node and python; let nix provide them.
    #
    # mkDefault so the host file can still say otherwise.
    my.platform.toolchainFromNix = lib.mkDefault true;

    # There is no compositor to hand a clipboard to. The `clipcopy` fish
    # function already covers this correctly for every host: it writes an
    # OSC 52 escape to the tty, which Windows Terminal honours, so copying out
    # of a WSL tmux pane into Windows works with no win32yank, no clip.exe
    # bridge and no X server. Nothing to configure — recorded so the absence
    # does not read as an oversight.

    # DELIBERATELY NOT SET:
    #
    #   TERM  — belongs to Windows Terminal (or whatever is attached), and
    #           modules/desktop/session.nix is the only place that overrides
    #           it. A WSL host never takes that aspect, so TERM is left alone.
    #           This is the whole reason those variables moved out of
    #           shell/core.nix.
    #
    #   BROWSER — `wslview` from the `wslu` package is the right answer if you
    #           want `xdg-open`-style handoff to Windows, but wslu is a distro
    #           package, not a nixpkgs one worth pinning here. Set it in the
    #           host file if you install it.
  };
}

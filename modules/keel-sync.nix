{ ... }:
{
  flake.modules.homeManager.keel-sync =
    { config, pkgs, ... }:
    let
      notify = pkgs.writeShellApplication {
        name = "keel-sync-run";
        runtimeInputs = with pkgs; [
          coreutils
          diffutils
          gh
          git
          gnugrep
          gnused
          jq
          openssh
        ];
        text = ''
          bin=''${KEEL_SYNC_BIN:-$HOME/dev/spain-flake/master/bin/keel-sync}
          out=''${KEEL_SYNC_OUT:-$HOME/notes/spain/keel-sync}
          state=''${XDG_STATE_HOME:-$HOME/.local/state}/keel-sync
          mkdir -p "$state"

          rc=0
          "$bin" --apply --out "$out" >"$state/last.txt" 2>&1 || rc=$?

          {
            grep -E '^  [A-Za-z0-9_.-]+ +[0-9a-f]{7}  ' "$state/last.txt" | grep -v '  current$' | sed 's/^  //; s/  */ /g'
            grep -E '^  github-only ' "$state/last.txt" | awk '{print $1, $2}'
          } | sort >"$state/lagging.new" || true
          touch "$state/lagging.txt"
          added=$(comm -13 "$state/lagging.txt" "$state/lagging.new")
          mv "$state/lagging.new" "$state/lagging.txt"

          if [ "$rc" = 0 ] && [ -z "$added" ]; then
            exit 0
          fi

          msg="keel-sync $(date +%F\ %H:%M): exit $rc"
          case $rc in
          1) msg="$msg (the tool failed; see journalctl --user -u keel-sync)" ;;
          2) msg="$msg (something diverged or needs a decision)" ;;
          esac
          if [ -n "$added" ]; then
            msg="$msg; newly lagging: $(printf '%s' "$added" | paste -sd ';' -)"
          fi
          msg="$msg; report $out/$(date +%F)/report.txt"

          if ! figaro send @96447061 -f -- "$msg"; then
            herald say --to gluck --from keel-sync --sender-id keel-sync "$msg" || true
          fi

          [ "$rc" = 1 ] && exit 1
          exit 0
        '';
      };
      home = config.home.homeDirectory;
    in
    {
      systemd.user.services.keel-sync = {
        Unit.Description = "keel-sync: pull GitHub-only pushes into keel, report spain's inputs against it";
        Service = {
          Type = "oneshot";
          ExecStart = "${notify}/bin/keel-sync-run";
          Environment = [
            "SSH_AUTH_SOCK=%t/gcr/ssh"
            "PATH=${home}/.nix-profile/bin:${home}/.local/state/hush/bin:/usr/bin:/bin"
          ];
        };
      };

      systemd.user.timers.keel-sync = {
        Unit.Description = "keel-sync, daily";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}

{
  flake.modules.homeManager.niri =
    { pkgs, ... }:
    let
      md-clipboard = pkgs.writeShellApplication {
        name = "md-clipboard";
        runtimeInputs = [ pkgs.pandoc ];
        text = ''
          out=''${TMPDIR:-/tmp}/clipboard.html
          wl-paste > "''${out%.html}.md"
          pandoc -f markdown+tex_math_dollars+tex_math_single_backslash \
            -t html5 --standalone --katex \
            --metadata title=clipboard -V maxwidth=52em \
            -o "$out" "''${out%.html}.md"
          exec helium-browser "$out"
        '';
      };
    in
    {
      home.packages = [ md-clipboard ];

      my.niri.bindsExtra = ''
        Mod+M { spawn "${md-clipboard}/bin/md-clipboard"; }
      '';
    };
}

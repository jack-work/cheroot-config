{ inputs, ... }:
{
  flake.modules.homeManager.splash =
    { lib, pkgs, ... }:
    let
      themeDir = "/usr/share/plymouth/themes/figaro";

      theme = pkgs.runCommand "plymouth-theme-figaro" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        mkdir $out
        src=${inputs.figaro}/assets/figaro-head-26.png
        magick "$src" -filter point -resize 1600% $out/logo.png
        rgb=$(magick "$src" -format '%[fx:p{0,0}.r] %[fx:p{0,0}.g] %[fx:p{0,0}.b]' info:)
        set -- $rgb

        cat > $out/figaro.plymouth <<PLY
        [Plymouth Theme]
        Name=Figaro
        Description=Figaro's head, centred
        ModuleName=script

        [script]
        ImageDir=${themeDir}
        ScriptFile=${themeDir}/figaro.script
        PLY

        cat > $out/figaro.script <<SCR
        Window.SetBackgroundTopColor($1, $2, $3);
        Window.SetBackgroundBottomColor($1, $2, $3);
        logo.image = Image("logo.png");
        logo.sprite = Sprite(logo.image);
        logo.sprite.SetX(Window.GetX() + Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
        logo.sprite.SetY(Window.GetY() + Window.GetHeight() / 2 - logo.image.GetHeight() / 2);
        SCR
      '';

      daemonConf = pkgs.writeText "plymouthd.conf" ''
        [Daemon]
        Theme=figaro
      '';

      diff = "${pkgs.diffutils}/bin/diff";
    in
    {
      my.preflight.pacman = [ "plymouth" ];

      home.activation.splashTheme = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        if ! ${diff} -rq ${theme} ${themeDir} >/dev/null 2>&1 \
          || ! ${diff} -q ${daemonConf} /etc/plymouth/plymouthd.conf >/dev/null 2>&1; then
          echo "splash: the Figaro boot splash is not installed. Run:" >&2
          echo "  sudo rm -rf ${themeDir} && sudo cp -r --no-preserve=mode,ownership ${theme} ${themeDir}" >&2
          echo "  sudo install -Dm644 ${daemonConf} /etc/plymouth/plymouthd.conf" >&2
          echo "  sudo mkinitcpio -P" >&2
          exit 1
        fi
      '';
    };
}

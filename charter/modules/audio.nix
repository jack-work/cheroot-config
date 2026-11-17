{
  flake.modules.homeManager.audio =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages =
        (with pkgs; [
          aubio
          loudgain
          opus-tools
          yt-dlp
          rubberband
          flac
          libsndfile
        ])
        ++ lib.optionals config.my.platform.mediaFromNix (
          with pkgs;
          [
            sox
            ffmpeg
          ]
        );
    };
}

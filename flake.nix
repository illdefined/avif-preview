{
  inputs = {
    eosyn.url = "git+https://woof.rip/mikael/eosyn.git";
  };
  
  outputs = { self, eosyn, ... }: let
    inherit (eosyn) lib;
  in {
    packages = lib.mapAttrs (system: pkgs: {
      default = pkgs.callPackage ({ writeShellApplication, ffmpeg }: writeShellApplication {
        name = "avif-preview";
        text = ''
          w="''${1:-1280}"
          h="''${2:-720}"

          exec ${lib.getExe ffmpeg} \
            -loglevel error \
            -hide_banner \
            -nostats \
            -i - \
            -map 0:v:0 \
            -frames:v 1 \
            -hwaccel:v auto \
            -filter:v "scale=w=min($w\\,iw):h=min($h\\,ih):interl=-1:force_original_aspect_ratio=decrease:force_divisible_by=max(ohsub\\,ovsub)" \
            -pix_fmt yuva420p \
            -codec:v libsvtav1 \
            -crf 30 \
            -preset 6 \
            -svtav1-params tune=2:enable-variance-boost=1:enable-overlays=1:enable-qm=1:qm-min=0:enable-tf=1 \
            -f avif \
            -
        '';
      }) {
        ffmpeg = pkgs.ffmpeg.override {
          ffmpegVariant = "headless";

          withAlsa = false;
          withAom = false;
          withAss = false;
          withCodec2 = false;
          withFontconfig = false;
          withFreetype = false;
          withGme = false;
          withHarfbuzz = false;
          withIconv = false;
          withJxl = true;
          withOpus = false;
          withPlacebo = false;
          withRist = false;
          withSoxr = false;
          withTheora = false;
          withV4l2 = false;
          withVoAmrwbenc = false;
          withVorbis = false;

          withNetwork = false;
          withBin = false;
          buildFfmpeg = true;
          withLib = false;
          withDocumentation = false;
          withStripping = true;

          svt-av1 = pkgs.svt-av1-psy;
        };
      };
    }) eosyn.legacyPackages;

    hydraJobs = lib.mapAttrs (system: packages: {
      default = lib.hydraJob packages.default;
    }) self.packages;
  };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  
  outputs = { self, nixpkgs, ... }: let
    inherit (nixpkgs) lib;
  in {
    packages = lib.genAttrs [ "riscv64-linux" "aarch64-linux" "x86_64-linux" ] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.callPackage ({ writeShellApplication, ffmpeg }: writeShellApplication {
        name = "avif-preview";
        text = ''
          w="''${3:-1280}"
          h="''${4:-720}"

          exec ${lib.getExe ffmpeg} \
            -loglevel fatal \
            -hide_banner \
            -nostats \
            -hwaccel:v auto \
            -i "$1" \
            -map 0:v:0 \
            -frames:v 1 \
            -filter:v "scale=w=min($w\\,iw):h=min($h\\,ih):interl=-1:force_original_aspect_ratio=decrease:force_divisible_by=2" \
            -pix_fmt yuva420p \
            -codec:v libsvtav1 \
            -crf 30 \
            -preset 6 \
            -svtav1-params tune=4:enable-variance-boost=1:enable-overlays=1:enable-qm=1:qm-min=0:enable-tf=1 \
            -f avif \
            "$2" 2> >(grep -E -v '^Svt\[(info|warn)\]:')
        '';

        # shellcheck is not yet available on RISC-V
        checkPhase = if pkgs.stdenv.buildPlatform.isRiscV then ''
          runHook preCheck
          ${pkgs.stdenv.shellDryRun} "$target"
          runHook postCheck
        '' else null;
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
          #withLib = false;
          withHtmlDoc = false;
          withManPages = false;
          withPodDoc = false;
          withTxtDoc = false;
          withStripping = true;

          svt-av1 = pkgs.svt-av1-psy;
        };
      };
    });

    hydraJobs = lib.mapAttrs (system: packages: {
      default = lib.hydraJob packages.default;
    }) self.packages;
  };
}

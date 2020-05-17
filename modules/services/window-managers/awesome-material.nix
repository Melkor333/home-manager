{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.xsession.windowManager.awesomeMaterial;
  material-pkg = pkgs.fetchFromGitHub {
    owner = "PapyElGringo";
    repo = "material-awesome";
    rev = "ad3933d2d12263a5b5d628b6436c6e27246e6700";
    sha256 = "1ihgxkbzx0kckzx17rnf2ww75baswrdpd4xx7xk6zjyigfgl98g1";
  };
in {
  options = {
    xsession.windowManager.awesomeMaterial = {
      enable = mkEnableOption "Material Theme for window manager.";
      package = mkOption {
        type = types.package;
        default = pkgs.awesome;
      };
    };
  };
  config = mkIf cfg.enable {
    services.picom.enable = true;
    xsession.windowManager.awesome.enable = true;
    home.packages = [
      pkgs.rofi
    ];
    xdg.configFile."awesome".source = "${material-pkg}";
  };

  #fonts.fonts = mkIf cfg.enable [
  #  pkgs.roboto
  #  pkgs.roboto-mono
  #  pkgs.roboto-slab
  #];
}

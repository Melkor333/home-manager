{ config, lib, pkgs, ... }:

with lib;

let
  # {{{ Configuration values
  cfg = config.xsession.windowManager.awesome;
  awesome = cfg.package;
  getLuaPath = lib: dir: "${lib}/${dir}/lua/${pkgs.luaPackages.lua.luaversion}";
  makeSearchPath = lib.concatMapStrings (path:
    " --search ${getLuaPath path "share"}"
    + " --search ${getLuaPath path "lib"}"
  );

  theme = mkOption {
    type = types.enum [
      ""
      "material"
    ];
    description = "Available Themes to be used out of the box.";
  };  

  configModule = types.submodule {
    options = {
      variables = mkOption {
        type = types.submodule {
          options = {
            terminal = mkOption {
              type = types.str;
              default = "${pkgs.xterm}/bin/xterm";
              description = "The default terminal to be used";
              example = "${pkgs.st}";
            };
            
            editor = mkOption {
              type = types.str;
              default = "${pkgs.nano}/bin/nano";
              description = "The default editor to be used";
              example = "${pkgs.emacs}/bin/emacsclient";
            };

            editor_cmd = mkOption {
              type = types.str;
              default = "terminal .. \" -e \" .. editor";
              description = "The command to start the editor. it will not be quotet in the config";
              example = "editor";
            };

            extraVariables = mkOption {
              type = types.attrsOf (types.nullOr types.str);
              default = {};

              description = ''
            An attribute set that assigns keys to variables where the value will be quoted.
            they will be put right after the errorhandling.
            '';
            };

            unquotedExtraVariables = mkOption {
              type = types.attrsOf (types.nullOr types.str);
              default = {};

              description = ''
            An attribute set that assigns keys to variables where the value will not be quoted.
            they will be put right after the quoted variables.
            '';
            };
          };
        };

      # TODO: more configs in the configModule
        default = {};
        description = "Window titlebar and border settings.";
      };
    };
  };
# }}}

# {{{ toString / Helper Functions
  variablesStr = variables: concatStringsSep "\n" (
    mapAttrsToList (variable: value: optionalString (value != null) "${variable} = \"${value}\"") variables
  );
  unquotedVariablesStr = variables: concatStringsSep "\n" (
    mapAttrsToList (variable: value: optionalString (value != null) "${variable} = ${value}") variables
  );
# }}}

# {{{ The effective configuration
  configFile = pkgs.writeText "rc.lua" ((if cfg.config != null && cfg.configFile != null then import cfg.configFile { pkgs=pkgs; config = cfg.config; lib = lib; } else "") + "\n" + cfg.extraConfig);

in
{
  imports = [
    ./awesome-themes/material.nix
  ];
  options = {
    xsession.windowManager.awesome = {
      enable = mkEnableOption "Awesome window manager.";

      package = mkOption {
        type = types.package;
        default = pkgs.awesome;
        defaultText = literalExample "pkgs.awesome";
        description = "Package to use for running the Awesome WM.";
      };

      config = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "awesome configuration options";
      };

      configFile = mkOption {
        #type = types.nullOr types.path;
        default = null;
        description = "A nixified configfile which can use the config variables";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/awesome/config.";
      };

      luaModules = mkOption {
          default = [];
          type = types.listOf types.package;
          description = ''
            List of lua packages available for being
            used in the Awesome configuration.
          '';
          example = literalExample "[ luaPackages.oocairo ]";
      };

      theme = mkOption {
        type = types.nullOr theme;
        default = null;
        description = "Select a Theme which sets the whole config (which should be able to override";
      };

      noArgb = mkOption {
          default = false;
          type = types.bool;
          description = ''
            Disable client transparency support, which can be greatly
            detrimental to performance in some setups
          '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ awesome ];

    xdg.configFile."awesome/rc.lua.test" = {
      source = configFile; # configFile;
      onChange = ''
            echo "Restarting awesome"
            echo 'awesome.restart()' | ${cfg.package}/bin/awesome-client
        '';
    };

    xsession.windowManager.command = 
      "${awesome}/bin/awesome "
      + optionalString cfg.noArgb "--no-argb "
      + makeSearchPath cfg.luaModules;
  };
}

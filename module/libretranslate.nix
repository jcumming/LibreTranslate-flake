{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (builtins) toString;

  cfg = config.services.libretranslate;

  stateDir = "/var/lib/libretranslate";

  serverArgs = with cfg;
    lib.concatStringsSep " " (
      [
        "--host ${host}"
        "--port ${toString port}"
        "--char-limit ${toString char-limit}"
        "--req-limit ${toString req-limit}"
        "--req-limit-storage ${req-limit-storage}"
        "--daily-req-limit ${toString daily-req-limit}"
        "--req-flood-threshold ${toString req-flood-threshold}"
        "--batch-limit ${toString batch-limit}"
        "--frontend-language-source ${frontend-language-source}"
        "--frontend-language-target ${frontend-language-target}"
        "--frontend-timeout ${toString frontend-timeout}"
        "--load-only ${load-only}"
        "--threads ${toString threads}"
      ]
      ++ lib.optional (url-prefix != "") "--url-prefix ${url-prefix}"
      ++ lib.optional suggestions "--suggestions"
      ++ lib.optional disable-files-translation "--disable-files-translation"
      ++ lib.optional disable-web-ui "--disable-web-ui"
      ++ lib.optional update-models "--update-models"
      ++ lib.optional debug "--debug"
      ++ lib.optional metrics "--metrics"
      ++ lib.optional (metrics && metrics-auth-token != "") "--metrics-auth-token ${metrics-auth-token} "
      ++ lib.optionals api-keys (
        ["--api-keys"]
        ++ lib.optional (api-keys-remote != "") "--api-keys-remote ${api-keys-remote}"
        ++ lib.optional (api-keys-db-path != "") "--api-keys-db-path ${api-keys-db-path}"
        ++ lib.optional (get-api-key-link != "") "--get-api-key-link ${get-api-key-link}"
        ++ lib.optional (require-api-key-origin != "") "--require-api-key-origin ${require-api-key-origin}"
        ++ lib.optional require-api-key-secret "--require-api-key-origin"
      )
    );

  mkAPI_Key_DB_Script = let
    # usage: ltmanage keys add [-h] [--key KEY] req_limit
    addKey = x: "${cfg.package}/bin/ltmanage keys --api-keys-db-path ${cfg.api-keys-db-path} add --key \"$(cat ${x})\" 1000";
    addKeys = lib.concatMapStringsSep "\n" (x: addKey x) cfg.api-key-files;
  in
    pkgs.writeScript "mk-api-key-db" ''
      #!${pkgs.bash}/bin/bash

      [ -e ${cfg.api-keys-db-path} ] && echo "Warning: recreating ${cfg.api-keys-db-path}"
      rm -f ${cfg.api-keys-db-path}
      touch ${cfg.api-keys-db-path}

      ${addKeys}
    '';
in {
  options = {
    services.libretranslate = {
      enable = mkEnableOption (lib.mdDoc "LibreTranslate");

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = lib.mdDoc "hostname to bind.";
      };

      port = mkOption {
        type = types.port;
        default = 5000;
        description = lib.mdDoc "port to bind.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.libretranslate;
        description = libmdDoc "libretranslate package to use";
      };

      char-limit = mkOption {
        type = types.int;
        default = -1;
        description = lib.mdDoc "Charactor limit of requests.";
      };

      req-limit = mkOption {
        type = types.int;
        default = -1;
        description = lib.mdDoc "Default maximum number of requests per minute per client.";
      };

      req-limit-storage = mkOption {
        type = types.str;
        default = "memory://";
        description = lib.mdDoc "Storage URI to use for request limit data storage. See https://flask-limiter.readthedocs.io/en/stable/configuration.html.";
      };

      daily-req-limit = mkOption {
        type = types.int;
        default = -1;
        description = lib.mdDoc "Default maximum number of requests per day per client, in addition to req-limit.";
      };

      req-flood-threshold = mkOption {
        type = types.int;
        default = -1;
        description = lib.mdDoc "Maximum number of request limit offences that a client can exceed before being banned.";
      };

      batch-limit = mkOption {
        type = types.int;
        default = -1;
        description = lib.mdDoc "Maximum number of texts to translate in a batch request";
      };

      debug = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable debug environment";
      };

      frontend-language-source = mkOption {
        type = types.str;
        default = "auto";
        description = lib.mdDoc "Frontend default language - source";
      };

      frontend-language-target = mkOption {
        type = types.str;
        default = "locale";
        description = lib.mdDoc "Frontend default language - target";
      };

      frontend-timeout = mkOption {
        type = types.int;
        default = 500;
        description = lib.mdDoc "Frontend translation timeout in ms";
      };

      api-keys = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable API keys database for per-user rate limits lookup";
      };

      api-key-files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = lib.mdDoc "list of files containing one API key. If the goal is to not have unencrypted API keys in the nix store, then ensure this is a string and not a path.";
      };

      api-keys-db-path = mkOption {
        type = types.str;
        default = "${stateDir}/api_keys.db";
        description = lib.mdDoc "Use a specific path inside the container for the local database. Can be absolute or relative.";
      };

      api-keys-remote = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Use this remote endpoint to query for valid API keys instead of using the local database";
      };

      get-api-key-link = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Show a link in the UI where to direct users to get an API key";
      };

      require-api-key-origin = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Require use of an API key for programmatic access to the API, unless the request origin matches this domain";
      };

      require-api-key-secret = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Require use of an API key for programmatic access to the API, unless the client also sends a secret match";
      };

      load-only = mkOption {
        type = types.str;
        default = "en,ja";
        description = lib.mdDoc "Set available languages (ar,de,en,es,fr,ga,hi,it,ja,ko,pt,ru,zh)";
      };

      threads = mkOption {
        type = types.int;
        default = 4;
        description = lib.mdDoc "number of threads";
      };

      suggestions = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "allow user suggestions"; # but but but user is always right?
      };

      disable-files-translation = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Disable files translation";
      };

      disable-web-ui = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Disable web ui";
      };

      update-models = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Update language models at startup";
      };

      metrics = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the /metrics endpoint for exporting Prometheus usage metrics";
      };

      metrics-auth-token = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Protect the /metrics endpoint by allowing only clients that have a valid Authorization Bearer token";
      };

      url-prefix = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Add prefix to URL: example.com:5000/url-prefix/";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.libretranslate = {
      description = "LibreTranslate daemon user";
      group = "libretranslate";
      isSystemUser = true;
      home = stateDir;
      createHome = true;
    };

    users.groups.libretranslate = {};

    systemd.services.libretranslate = {
      description = "Libretranslate language translation server. ";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      preStart = ''
        ${mkAPI_Key_DB_Script}
      '';

      serviceConfig = {
        User = "libretranslate";
        Group = "libretranslate";
        WorkingDirectory = stateDir;
        ExecStart = "${cfg.package}/bin/libretranslate ${serverArgs}";
      };
    };
  };

  meta.maintainers = with lib.maintainers; [jcumming];
}

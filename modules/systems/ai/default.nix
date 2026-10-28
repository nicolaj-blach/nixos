{ metaOwner, ... }:

{
  # Local AI gateway:
  #   ollama (local models, GPU) + OpenRouter -> LiteLLM (127.0.0.1:4000)
  #   atuin-ai-server (127.0.0.1:8080) -> LiteLLM
  flake.nixosModules.ai =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      ...
    }:
    let
      cfg = config.ai;

      # The open kernel modules only support Turing (RTX 20xx) and newer, which is also what
      # the prebuilt ollama-cuda supports; older cards stay on Vulkan
      cuda = lib.elem "nvidia" config.services.xserver.videoDrivers && config.hardware.nvidia.open;

      ports = {
        ollama = 11434;
        gateway = 4000;
        atuin = 8080;
      };

      envFile = config.sops.templates."ai-gateway.env".path;
      tokenFile = config.sops.secrets.ai-gateway-token.path;
      localContext = 16384;

      inherit (import ./_litellm.nix { inherit pkgs lib; }) python litellm;
      localDb = cfg.database.environmentFile == null;

      # Generated model configs for atuin-ai-server, opencode and pi, plus cached model lists
      stateDir = "/var/lib/ai-gateway";

      scripts = import ./_scripts.nix {
        inherit
          pkgs
          lib
          cfg
          ports
          stateDir
          tokenFile
          localContext
          ;
      };
    in
    {
      options.ai = {
        enable = lib.mkEnableOption "local AI gateway (ollama, LiteLLM, atuin-ai-server)";

        rocm = lib.mkEnableOption "ROCm for ollama on a supported AMD GPU instead of Vulkan";

        models = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "qwen2.5:7b"
            "llama3.2:3b"
          ];
          description = "Ollama models pulled on activation.";
        };

        defaultModel = lib.mkOption {
          type = lib.types.str;
          # llama3.2:3b emits malformed tool calls with atuin; qwen2.5:7b handles them
          default = "ollama/qwen2.5:7b";
        };

        database.environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            File with DATABASE_URL=postgresql://... for LiteLLM's spend tracking, e.g. a sops
            template. null runs a local PostgreSQL for LiteLLM only.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # Prebuilt CUDA packages (ollama-cuda is unfree, so not on cache.nixos.org)
        nix.settings = lib.mkIf cuda {
          substituters = [ "https://cache.nixos-cuda.org" ];
          trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
        };

        services.ollama = {
          enable = true;
          # Vulkan runs on any GPU vendor; ollama falls back to CPU without one
          package =
            if cuda then
              unstablePkgs.ollama-cuda
            else if cfg.rocm then
              unstablePkgs.ollama-rocm
            else
              unstablePkgs.ollama-vulkan;
          host = "127.0.0.1";
          port = ports.ollama;
          loadModels = cfg.models;
          # Coding agents send 8-20k tokens per request; 16k covers that
          environmentVariables = {
            OLLAMA_CONTEXT_LENGTH = toString localContext;
          }
          // lib.optionalAttrs (!cuda && !cfg.rocm) { OLLAMA_VULKAN = "1"; };
        };

        services.litellm = {
          enable = true;
          host = "127.0.0.1";
          port = ports.gateway;
          environmentFile = envFile;
          settings = {
            model_list = [
              {
                model_name = "openrouter/*";
                litellm_params = {
                  model = "openrouter/*";
                  api_key = "os.environ/OPENROUTER_API_KEY";
                };
              }
              {
                model_name = "ollama/*";
                litellm_params = {
                  # Ollama's OpenAI-compatible API accepts content-part arrays (ollama_chat doesn't)
                  model = "openai/*";
                  api_base = "http://127.0.0.1:${toString ports.ollama}/v1";
                  api_key = "ollama";
                };
              }
            ];
            general_settings.master_key = "os.environ/AUTH_TOKEN";
            litellm_settings.drop_params = true;
          };
          package = litellm;
          environment = {
            # The schema is pushed in preStart; LiteLLM only checks it
            DISABLE_SCHEMA_UPDATE = "true";
            CHECKPOINT_DISABLE = "1";
            HOME = "/var/lib/litellm";
          }
          // lib.optionalAttrs localDb {
            DATABASE_URL = "postgresql://litellm@localhost/litellm?host=/run/postgresql";
          };
        };

        systemd.services.litellm = {
          # LiteLLM downloads its price list at start and falls back to an old copy when offline
          after = [ "network-online.target" ] ++ lib.optional localDb "postgresql-setup.service";
          wants = [ "network-online.target" ];
          requires = lib.optional localDb "postgresql-setup.service";
          serviceConfig = {
            User = "litellm";
            EnvironmentFile = lib.optional (!localDb) cfg.database.environmentFile;
          };
          preStart = ''
            ${lib.getExe pkgs.prisma_6} db push --skip-generate --accept-data-loss \
              --schema ${litellm}/${python.sitePackages}/litellm/proxy/schema.prisma
          '';
        };

        services.postgresql = lib.mkIf localDb {
          enable = true;
          package = pkgs.postgresql_17;
          ensureDatabases = [ "litellm" ];
          ensureUsers = [
            {
              name = "litellm";
              ensureDBOwnership = true;
            }
          ];
        };

        virtualisation.podman.enable = true;

        virtualisation.oci-containers.containers.atuin-ai-server = {
          image = "ghcr.io/atuinsh/atuin-ai-server@sha256:3d11028588ebfddb0685169e35cbc7121d3577b6eee3831e845fbe5c28e48d92";
          environmentFiles = [ envFile ];
          volumes = [ "${stateDir}/atuin.toml:/etc/atuin-ai/config.toml:ro" ];
          extraOptions = [ "--network=host" ];
        };

        systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];

        # Model configs for atuin-ai-server, opencode and pi: at boot, hourly, and by ai-refresh
        systemd.services.ai-models = {
          description = "Generate AI gateway model configs";
          after = [
            "ollama.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe scripts.aiModels;
          };
        };

        systemd.timers.ai-models = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "hourly";
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.podman-atuin-ai-server = rec {
          after = [
            "ai-models.service"
            "litellm.service"
            "ollama.service"
          ];
          wants = after;
        };

        # Let the user refresh the model lists without a password
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                ["ai-models.service", "podman-atuin-ai-server.service"].indexOf(action.lookup("unit")) >= 0 &&
                action.lookup("verb") == "restart" &&
                subject.user == "${metaOwner.username}") {
              return polkit.Result.YES;
            }
          });
        '';

        # opencode and pi get a "litellm" provider next to their own ones; atuin and zsh get Atuin AI
        home-manager.sharedModules = [
          (
            { config, lib, ... }:
            {
              home.sessionVariables.OPENCODE_CONFIG = "${stateDir}/opencode.json";
              home.file.".pi/agent/models.json".source =
                config.lib.file.mkOutOfStoreSymlink "${stateDir}/pi-models.json";

              programs.atuin = {
                daemon.enable = true;
                settings = {
                  ai = {
                    enabled = true;
                    endpoint = "http://127.0.0.1:${toString ports.atuin}";
                    endpoint_protocol = "oss";
                    tips = false;
                  };
                  pty_proxy.enabled = true;
                };
              };

              programs.zsh.initContent = lib.mkOrder 2000 (builtins.readFile ./ai.zsh);
            }
          )
        ];

        environment.systemPackages = [
          scripts.aiRefresh
          scripts.aiModel
          scripts.aiUsage
          litellm
        ];
      };
    };
}

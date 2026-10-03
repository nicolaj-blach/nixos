{ inputs, metaOwner, ... }:

{
  # Local AI gateway:
  #   ollama (local models, GPU) + OpenRouter -> LiteLLM (127.0.0.1:4000)
  #   atuin-ai-server (127.0.0.1:8080) -> LiteLLM
  flake.nixosModules.ai =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ai;
      unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      ollamaPackage =
        {
          nvidia = unstable.ollama-cuda;
          amd = unstable.ollama-rocm;
          none = unstable.ollama;
        }
        .${cfg.gpu};

      envFile = config.sops.templates."ai-gateway.env".path;
      serverDir = "/var/lib/atuin-ai-server";

      # Writes atuin-ai-server's config with every tool-capable model it can reach
      atuinModels = pkgs.writeShellApplication {
        name = "atuin-ai-models";
        runtimeInputs = with pkgs; [
          curl
          jq
          coreutils
        ];
        text = ''
          out=${serverDir}/config.toml
          tmp=$(mktemp)

          {
            curl -fsS --max-time 20 https://openrouter.ai/api/v1/models \
              | jq -c '.data[] | select(.supported_parameters | index("tools"))
                  | { alias: ("openrouter/" + .id), name: .name, description: "OpenRouter", model: ("openrouter/" + .id) }' \
              || echo "OpenRouter unreachable, skipping its models" >&2

            curl -fsS --max-time 10 --retry 10 --retry-connrefused --retry-delay 2 \
              http://127.0.0.1:${toString cfg.ollamaPort}/api/tags \
              | jq -c '.models[] | { alias: ("ollama/" + .name), name: .name, description: "Local (Ollama)", model: ("ollama/" + .name) }' \
              || echo "Ollama unreachable, skipping its models" >&2
          } > "$tmp"

          # Nothing reachable: fall back to the declared ollama models so the server still starts
          if [ ! -s "$tmp" ]; then
            echo "No models found; using declared ollama models" >&2
            for m in ${lib.escapeShellArgs cfg.models}; do
              jq -cn --arg m "$m" '{ alias: ("ollama/" + $m), name: $m, description: "Local (Ollama)", model: ("ollama/" + $m) }'
            done > "$tmp"
          fi
          count=$(wc -l < "$tmp")

          default=${lib.escapeShellArg cfg.defaultModel}
          grep -qF "\"alias\":\"$default\"" "$tmp" || default=$(head -n1 "$tmp" | jq -r .alias)

          {
            echo 'port = ${toString cfg.atuinPort}'
            echo 'endpoint = "http://127.0.0.1:${toString cfg.gatewayPort}/v1"'
            echo 'api_key = { env = "AUTH_TOKEN" }'
            printf 'default_model = %s\n' "$(jq -Rn --arg v "$default" '$v')"
            echo
            echo '[request.body]'
            echo 'stream_options = { include_usage = true }'
            jq -r '"\n[[models]]",
              "alias = \(.alias | tojson)",
              "name = \(.name | tojson)",
              "description = \(.description | tojson)",
              "model = \(.model | tojson)"' "$tmp"
          } > "$out.new"

          mv "$out.new" "$out"
          chmod 0644 "$out"
          rm -f "$tmp"
          echo "atuin-ai-server: $count models, default $default"
        '';
      };

      aiRefresh = pkgs.writeShellApplication {
        name = "ai-refresh";
        runtimeInputs = with pkgs; [
          systemd
          libnotify
          gnugrep
        ];
        text = ''
          if systemctl restart podman-atuin-ai-server.service; then
            n=$(grep -c '^\[\[models\]\]' ${serverDir}/config.toml || true)
            notify-send -a "AI" "AI models refreshed" "$n models available"
          else
            notify-send -u critical -a "AI" "AI refresh failed" "journalctl -u podman-atuin-ai-server"
            exit 1
          fi
        '';
      };
    in
    {
      options.ai = {
        enable = lib.mkEnableOption "local AI gateway (ollama, LiteLLM, atuin-ai-server)";

        gpu = lib.mkOption {
          type = lib.types.enum [
            "nvidia"
            "amd"
            "none"
          ];
          default =
            let
              usesAmdgpu =
                lib.elem "amdgpu" config.services.xserver.videoDrivers
                || config.hardware.amdgpu.initrd.enable
                || lib.elem "amdgpu" config.boot.initrd.kernelModules
                || lib.any (lib.hasPrefix "amdgpu.") config.boot.kernelParams;
            in
            if lib.elem "nvidia" config.services.xserver.videoDrivers then
              "nvidia"
            else if usesAmdgpu then
              "amd"
            else
              "none";
          description = "GPU backend for ollama: CUDA (nvidia), ROCm (amd) or CPU only.";
        };

        rocmOverrideGfx = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "10.3.0";
          description = "HSA_OVERRIDE_GFX_VERSION for AMD GPUs ROCm doesn't detect.";
        };

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
          default = "ollama/llama3.2:3b";
        };

        ollamaPort = lib.mkOption {
          type = lib.types.port;
          default = 11434;
        };
        gatewayPort = lib.mkOption {
          type = lib.types.port;
          default = 4000;
        };
        atuinPort = lib.mkOption {
          type = lib.types.port;
          default = 8080;
        };
      };

      config = lib.mkIf cfg.enable {
        # Prebuilt CUDA packages (ollama-cuda is unfree, so not on cache.nixos.org)
        nix.settings = lib.mkIf (cfg.gpu == "nvidia") {
          substituters = [ "https://cache.nixos-cuda.org" ];
          trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
        };

        services.ollama = {
          enable = true;
          package = ollamaPackage;
          host = "127.0.0.1";
          port = cfg.ollamaPort;
          loadModels = cfg.models;
          rocmOverrideGfx = lib.mkIf (cfg.gpu == "amd") cfg.rocmOverrideGfx;
        };

        services.litellm = {
          enable = true;
          host = "127.0.0.1";
          port = cfg.gatewayPort;
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
                  model = "ollama_chat/*";
                  api_base = "http://127.0.0.1:${toString cfg.ollamaPort}";
                };
              }
            ];
            general_settings.master_key = "os.environ/AUTH_TOKEN";
            litellm_settings.drop_params = true;
          };
        };

        virtualisation.podman = {
          enable = true;
          dockerCompat = true;
        };

        virtualisation.oci-containers = {
          backend = "podman";
          containers.atuin-ai-server = {
            image = "ghcr.io/atuinsh/atuin-ai-server@sha256:3d11028588ebfddb0685169e35cbc7121d3577b6eee3831e845fbe5c28e48d92";
            environmentFiles = [ envFile ];
            volumes = [ "${serverDir}/config.toml:/etc/atuin-ai/config.toml:ro" ];
            extraOptions = [ "--network=host" ];
          };
        };

        systemd.tmpfiles.rules = [ "d ${serverDir} 0755 root root -" ];

        systemd.services.podman-atuin-ai-server = {
          after = [
            "litellm.service"
            "ollama.service"
            "network-online.target"
          ];
          wants = [
            "litellm.service"
            "ollama.service"
            "network-online.target"
          ];
          serviceConfig.ExecStartPre = lib.mkBefore [ (lib.getExe atuinModels) ];
        };

        # Let the user refresh the model list without a password
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "podman-atuin-ai-server.service" &&
                action.lookup("verb") == "restart" &&
                subject.user == "${metaOwner.username}") {
              return polkit.Result.YES;
            }
          });
        '';

        environment.systemPackages = [
          aiRefresh
          ollamaPackage
        ];
      };
    };
}

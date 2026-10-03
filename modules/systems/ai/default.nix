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
          cuda = unstable.ollama-cuda;
          rocm = unstable.ollama-rocm;
          vulkan = unstable.ollama-vulkan;
          cpu = unstable.ollama;
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

          local_model() {
            jq -cn --arg m "$1" '{ alias: ("ollama/" + $m), name: $m, description: "Local (Ollama)", model: ("ollama/" + $m) }'
          }

          {
            # Local first: declared models (may still be downloading), then anything else pulled
            for m in ${lib.escapeShellArgs cfg.models}; do local_model "$m"; done
            curl -fsS --max-time 10 --retry 10 --retry-connrefused --retry-delay 2 \
              http://127.0.0.1:${toString cfg.ollamaPort}/api/tags \
              | jq -r '.models[].name' \
              | while read -r m; do local_model "$m"; done \
              || echo "Ollama unreachable, using declared models only" >&2

            curl -fsS --max-time 20 https://openrouter.ai/api/v1/models \
              | jq -c '.data[] | select(.supported_parameters | index("tools"))
                  | { alias: ("openrouter/" + .id), name: .name, description: "OpenRouter", model: ("openrouter/" + .id) }' \
              || echo "OpenRouter unreachable, skipping its models" >&2
          } | jq -sc 'unique_by(.alias) | sort_by(.description != "Local (Ollama)") | .[]' > "$tmp"
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

      # One row per model: alias <TAB> visible columns <TAB> preview text
      modelRows = pkgs.writeText "ai-model-rows.jq" ''
        def money: if . == null then null else (tonumber * 1000000) end;
        def usd: if . == null then "-" elif . == 0 then "free" elif . < 0.01 then "<$0.01" else "$" + ((. * 100 | round) / 100 | tostring | if test("\\.") then (if test("\\.[0-9]$") then . + "0" else . end) else . + ".00" end) end;
        def ctx: if . == null then "" elif . >= 1000000 then ((. / 1000000 * 10 | round) / 10 | tostring) + "M ctx" elif . >= 1000 then ((. / 1000 | round) | tostring) + "K ctx" else tostring + " ctx" end;
        def gb: ((. / 1e9 * 10 | round) / 10 | tostring) + " GB";
        def pad($n): tostring | if length >= $n then .[0:$n] else . + (" " * ($n - length)) end;

        ($or[0].data // [] | map({ key: ("openrouter/" + .id), value: . }) | from_entries) as $routes
        | ($ol[0].models // [] | map({ key: ("ollama/" + .name), value: . }) | from_entries) as $locals
        | $srv[0].models[]
        | .alias as $a
        | ($routes[$a]) as $r
        | ($locals[$a]) as $l
        | (if $a == $cur then "* " else "  " end) as $mark
        | if $l != null or ($a | startswith("ollama/")) then
            [ $a,
              $mark + (.name | pad(40)) + "  " + ("local" | pad(18)) + "  "
                + ((($l.details.parameter_size // "?") + " " + ($l.details.quantization_level // "")) | pad(14))
                + ($l.size | if . then gb else "" end),
              ([ .name, $a, "",
                 "Runs locally with Ollama (free)",
                 "Parameters:   " + ($l.details.parameter_size // "?"),
                 "Quantization: " + ($l.details.quantization_level // "?"),
                 "Family:       " + ($l.details.family // "?"),
                 "Size on disk: " + ($l.size | if . then gb else "?" end)
               ] | join("\\n"))
            ]
          else
            ($r.pricing.prompt | money) as $in
            | ($r.pricing.completion | money) as $out
            | [ $a,
                $mark + (.name | pad(40)) + "  " + (($in | usd) + " / " + ($out | usd) | pad(18)) + "  "
                  + ($r.context_length | ctx),
                ([ .name, $a, "",
                   "Price per 1M tokens",
                   "  input:       " + ($in | usd),
                   "  output:      " + ($out | usd),
                   "  cache read:  " + ($r.pricing.input_cache_read | money | usd),
                   "  cache write: " + ($r.pricing.input_cache_write | money | usd),
                   "  web search:  " + ($r.pricing.web_search | if . == null then "-" else "$" + . + " / search" end),
                   "",
                   "Context:     " + ($r.context_length | ctx),
                   "Max output:  " + ($r.top_provider.max_completion_tokens // "?" | tostring) + " tokens",
                   "Inputs:      " + (($r.architecture.input_modalities // []) | join(", ")),
                   "",
                   ($r.description // "" | gsub("[\\t\\n]+"; " "))
                 ] | join("\\n"))
              ]
          end
        | @tsv
      '';

      aiModel = pkgs.writeShellApplication {
        name = "ai-model";
        runtimeInputs = with pkgs; [
          curl
          jq
          fzf
          coreutils
          gnused
        ];
        text = ''
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/atuin/ai-model"

          if [ "''${1:-}" = "--reset" ]; then
            rm -f "$state"
            echo "AI model: server default"
            exit 0
          fi

          token_file=/run/secrets/ai-gateway-token
          [ -r "$token_file" ] || { echo "ai-model: can't read $token_file" >&2; exit 1; }
          cur=$(cat "$state" 2>/dev/null || true)

          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          curl -fsS --max-time 10 -H "Authorization: Bearer $(cat "$token_file")" \
            http://127.0.0.1:${toString cfg.atuinPort}/api/cli/models > "$tmp/srv.json" &
          curl -fsS --max-time 20 https://openrouter.ai/api/v1/models > "$tmp/or.json" 2>/dev/null &
          curl -fsS --max-time 5 http://127.0.0.1:${toString cfg.ollamaPort}/api/tags > "$tmp/ol.json" 2>/dev/null &
          wait

          [ -s "$tmp/srv.json" ] || { echo "ai-model: AI server not reachable (try ai-refresh)" >&2; exit 1; }
          [ -s "$tmp/or.json" ] || echo '{}' > "$tmp/or.json"
          [ -s "$tmp/ol.json" ] || echo '{}' > "$tmp/ol.json"

          default=$(jq -r '.default' "$tmp/srv.json")
          [ -n "$cur" ] || cur=$default

          jq -r --arg cur "$cur" \
            --slurpfile srv "$tmp/srv.json" --slurpfile or "$tmp/or.json" --slurpfile ol "$tmp/ol.json" \
            -n -f ${modelRows} > "$tmp/rows"

          # Current model first
          { grep -F "$(printf '%s\t' "$cur")" "$tmp/rows" || true
            grep -vF "$(printf '%s\t' "$cur")" "$tmp/rows" || true; } > "$tmp/sorted"

          choice=$(fzf --delimiter $'\t' --with-nth 2 --accept-nth 1 \
            --header "AI model: $cur   (price = \$ per 1M tokens in / out)" \
            --header-first --layout reverse --height 80% \
            --preview 'echo {3} | sed "s/\\\\n/\n/g"' --preview-window 'right,45%,wrap' \
            < "$tmp/sorted") || exit 0

          [ -n "$choice" ] || exit 0
          mkdir -p "$(dirname "$state")"
          if [ "$choice" = "$default" ]; then
            rm -f "$state"
          else
            printf '%s\n' "$choice" > "$state"
          fi
          echo "AI model: $choice"
        '';
      };
    in
    {
      options.ai = {
        enable = lib.mkEnableOption "local AI gateway (ollama, LiteLLM, atuin-ai-server)";

        gpu = lib.mkOption {
          type = lib.types.enum [
            "vulkan"
            "cuda"
            "rocm"
            "cpu"
          ];
          default =
            let
              usesNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
              usesAmdgpu =
                lib.elem "amdgpu" config.services.xserver.videoDrivers
                || config.hardware.amdgpu.initrd.enable
                || lib.elem "amdgpu" config.boot.initrd.kernelModules
                || lib.any (lib.hasPrefix "amdgpu.") config.boot.kernelParams;
            in
            if usesNvidia || usesAmdgpu then "vulkan" else "cpu";
          description = ''
            Ollama GPU backend. vulkan works on any NVIDIA or AMD GPU (default when one is found).
            cuda is faster on NVIDIA Turing (RTX 20xx) and newer; the cached build skips older
            cards like the GTX 1080. rocm targets supported AMD GPUs.
          '';
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
          # llama3.2:3b emits malformed tool calls with atuin; qwen2.5:7b handles them
          default = "ollama/qwen2.5:7b";
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
        nix.settings = lib.mkIf (cfg.gpu == "cuda") {
          substituters = [ "https://cache.nixos-cuda.org" ];
          trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
        };

        services.ollama = {
          enable = true;
          package = ollamaPackage;
          host = "127.0.0.1";
          port = cfg.ollamaPort;
          loadModels = cfg.models;
          rocmOverrideGfx = lib.mkIf (cfg.gpu == "rocm") cfg.rocmOverrideGfx;
          environmentVariables = lib.mkIf (cfg.gpu == "vulkan") { OLLAMA_VULKAN = "1"; };
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
                  # Ollama's OpenAI-compatible API accepts content-part arrays (ollama_chat doesn't)
                  model = "openai/*";
                  api_base = "http://127.0.0.1:${toString cfg.ollamaPort}/v1";
                  api_key = "ollama";
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
          aiModel
          ollamaPackage
        ];
      };
    };
}

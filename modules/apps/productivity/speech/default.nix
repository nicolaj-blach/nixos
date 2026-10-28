{ ... }:

{
  # Speech to text: hold Super+Space (kanata sends F13 while held) to dictate.
  # Text to speech: Mod+Shift+R reads the selection in English, Mod+Alt+R in Danish.
  flake.homeManagerModules.speech =
    { pkgs, ... }:
    let
      hf = "https://huggingface.co";

      whisperModel = pkgs.fetchurl {
        url = "${hf}/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
        hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
      };

      voxtype = pkgs.voxtype.override { vulkanSupport = true; };

      voxtypeConfig = (pkgs.formats.toml { }).generate "voxtype.toml" {
        state_file = "auto";
        hotkey = {
          enabled = true;
          key = "F13";
          mode = "push_to_talk";
        };
        audio = {
          device = "default";
          sample_rate = 16000;
          max_duration_secs = 120;
          feedback = {
            enabled = true;
            theme = "subtle";
            volume = 0.5;
          };
        };
        whisper = {
          model = "${whisperModel}";
          context_window_optimization = true;
          language = [
            "en"
            "da"
          ];
        };
        output = {
          mode = "type";
          fallback_to_clipboard = true;
          notification = {
            on_recording_start = false;
            on_recording_stop = false;
            on_transcription = false;
          };
        };
      };

      # swayosd popup for dictation, redrawn every 80ms (swayosd hides it after 1s):
      # Starting (mic still waking up, only silence so far), then Listening with
      # the live mic level, then Transcribing.
      voxtype-osd = pkgs.writers.writePython3Bin "voxtype-osd" { flakeIgnore = [ "E501" ]; } ''
        import os
        import socket
        import struct
        import subprocess
        import time

        run = os.environ["XDG_RUNTIME_DIR"] + "/voxtype/"
        mic = "audio-input-microphone-symbolic"


        def osd(icon, text, *args):
            subprocess.run(["${pkgs.swayosd}/bin/swayosd-client", "--custom-icon", icon,
                            "--custom-progress-text", text, *args],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


        def spinner(icon, text, tick):
            osd(icon, text, "--custom-segmented-progress", f"{(tick // 2) % 6}:5")


        sock = None
        buf = b""
        heard = False
        level = 0.0
        tick = 0
        while True:
            try:
                state = open(run + "state").read().strip()
            except OSError:
                state = "idle"

            if sock is None:
                try:
                    sock = socket.socket(socket.AF_UNIX)
                    sock.connect(run + "audio.sock")
                    sock.setblocking(False)
                except OSError:
                    sock = None

            peak = 0.0
            if sock is not None:
                try:
                    while True:
                        data = sock.recv(4096)
                        if not data:
                            raise OSError
                        buf += data
                except BlockingIOError:
                    pass
                except OSError:
                    sock.close()
                    sock = None
                    buf = b""
                while len(buf) >= 16:
                    db = struct.unpack("=Ifff", buf[:16])[3]
                    buf = buf[16:]
                    if db > -119:
                        heard = True
                    peak = max(peak, min(1.0, max(0.0, (db + 60) / 60)))
            level = max(peak, level * 0.7)

            if state == "recording":
                if heard:
                    osd(mic, "Listening", "--custom-progress", f"{level:.2f}")
                else:
                    spinner(mic, "Starting", tick)
            elif state == "transcribing":
                spinner("content-loading-symbolic", "Transcribing", tick)
            else:
                heard = False

            tick += 1
            time.sleep(0.08)
      '';

      piper = pkgs.piper-tts.override {
        withTrain = false;
        withHTTP = false;
        withAlignment = false;
      };

      # piper ignores -c and reads <model>.onnx.json next to the model
      voice =
        path: onnxHash: jsonHash:
        let
          name = baseNameOf path;
        in
        "${
          pkgs.linkFarm name {
            "${name}.onnx" = pkgs.fetchurl {
              url = "${hf}/rhasspy/piper-voices/resolve/main/${path}.onnx";
              hash = onnxHash;
            };
            "${name}.onnx.json" = pkgs.fetchurl {
              url = "${hf}/rhasspy/piper-voices/resolve/main/${path}.onnx.json";
              hash = jsonHash;
            };
          }
        }/${name}.onnx";

      voices = {
        en =
          voice "en/en_US/lessac/medium/en_US-lessac-medium" "sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8="
            "sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=";
        da =
          voice "da/da_DK/talesyntese/medium/da_DK-talesyntese-medium"
            "sha256-uSce/SX3uElLvSjUjdZ1yMEZ2qKE8+5IgAiTX1FfEkE="
            "sha256-if4TvSUUBswAiFcNED6nrDWCMhHYRm+vkTJoq4UG9Bs=";
      };

      # Usage: speak en|da [text]. Without text it reads the primary selection.
      # Running it while speaking stops instead.
      speak = pkgs.writeShellApplication {
        name = "speak";
        runtimeInputs = [
          pkgs.wl-clipboard
          pkgs.libnotify
        ];
        text = ''
          if systemctl --user is-active --quiet speak; then
            systemctl --user stop speak
            exit
          fi

          case ''${1:-en} in
            da) model=${voices.da} ;;
            *) model=${voices.en} ;;
          esac
          shift || true

          file="$XDG_RUNTIME_DIR/speak.txt"
          if [ $# -gt 0 ]; then printf '%s\n' "$*" > "$file"; else wl-paste --primary --no-newline > "$file" 2>/dev/null || true; fi
          # Join wrapped lines (PDFs) so piper reads it as one text
          sed -i -e ':a;N;$!ba' -e 's/-\n//g; s/\n/ /g' "$file"
          if [ ! -s "$file" ]; then
            notify-send --app-name=speak "Nothing selected"
            exit 1
          fi

          systemd-run --user --quiet --collect --unit=speak ${pkgs.bash}/bin/sh -c \
            "${piper}/bin/piper -m $model -i $file --output-raw \
              | ${pkgs.pipewire}/bin/pw-play --raw --rate 22050 --channels 1 --format s16 -"
        '';
      };
    in
    {
      home.packages = [
        voxtype
        speak
      ];

      xdg.configFile."voxtype/config.toml".source = voxtypeConfig;

      systemd.user.services.voxtype = {
        Unit = {
          Description = "voxtype push-to-talk dictation";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "pipewire.service"
          ];
        };
        Service = {
          ExecStart = "${voxtype}/bin/voxtype daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.voxtype-osd = {
        Unit = {
          Description = "swayosd popup for voxtype";
          PartOf = [ "graphical-session.target" ];
          After = [ "voxtype.service" ];
        };
        Service = {
          ExecStart = "${voxtype-osd}/bin/voxtype-osd";
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      custom.niri.binds = {
        "Mod+Shift+R" = [
          "speak"
          "en"
        ];
        "Mod+Alt+R" = [
          "speak"
          "da"
        ];
      };
    };
}

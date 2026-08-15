{
  description = "OpenAI ChatGPT for Linux, repackaged from the official deb";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    chatgpt-deb = {
      url = "file+https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
      flake = false;
    };
  };

  outputs = { nixpkgs, chatgpt-deb, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      payload = pkgs.stdenvNoCC.mkDerivation {
        pname = "chatgpt-payload";
        version = "latest";
        src = chatgpt-deb;

        nativeBuildInputs = [ pkgs.dpkg ];
        dontUnpack = true;
        dontFixup = true;

        installPhase = ''
          runHook preInstall

          package_root="$TMPDIR/package"
          mkdir -p "$package_root"
          dpkg-deb -x "$src" "$package_root"

          test -x "$package_root/usr/lib/chatgpt/ChatGPT"
          test -f "$package_root/usr/share/applications/chatgpt.desktop"
          test -f "$package_root/usr/share/pixmaps/chatgpt.png"

          mkdir -p "$out/lib" "$out/share/applications" "$out/share/pixmaps"
          cp -a "$package_root/usr/lib/chatgpt" "$out/lib/chatgpt"
          cp "$package_root/usr/share/applications/chatgpt.desktop" \
            "$out/share/applications/chatgpt.desktop"
          cp "$package_root/usr/share/pixmaps/chatgpt.png" \
            "$out/share/pixmaps/chatgpt.png"

          runHook postInstall
        '';
      };

      runtime = pkgs.buildFHSEnv {
        name = "chatgpt";
        runScript = "${payload}/lib/chatgpt/codex-launcher";

        targetPkgs = p: with p; [
          alsa-lib
          at-spi2-atk
          at-spi2-core
          atk
          cairo
          coreutils
          cups
          dbus
          expat
          gdk-pixbuf
          git
          glib
          graphite2
          gtk3
          libdrm
          libgbm
          libglvnd
          libnotify
          libusb1
          libxkbcommon
          mesa
          nspr
          nss
          pango
          stdenv.cc.cc.lib
          systemd
          wayland
          xdg-utils
          xz
          zlib
          libX11
          libXcomposite
          libXdamage
          libXext
          libXfixes
          libXrandr
          libxcb
        ];
      };

      chatgpt = pkgs.symlinkJoin {
        name = "chatgpt";
        paths = [ payload runtime ];

        meta = {
          description = "ChatGPT by OpenAI";
          homepage = "https://developers.openai.com/codex/app";
          license = pkgs.lib.licenses.unfree;
          platforms = [ system ];
          mainProgram = "chatgpt";
        };
      };
    in
    {
      packages.${system} = {
        inherit chatgpt;
        default = chatgpt;
      };

      apps.${system} = {
        chatgpt = {
          type = "app";
          program = "${chatgpt}/bin/chatgpt";
        };
        default = {
          type = "app";
          program = "${chatgpt}/bin/chatgpt";
        };
      };
    };
}

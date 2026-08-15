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
      lib = pkgs.lib;

      runtimeLibraries = with pkgs; [
        alsa-lib
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        gdk-pixbuf
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
        openssl
        pango
        pipewire
        systemd
        stdenv.cc.cc.lib
        wayland
        xz
        zstd
        libX11
        libXcomposite
        libXcursor
        libXdamage
        libXext
        libXfixes
        libXi
        libXrandr
        libXScrnSaver
        libXtst
        libxcb
        libxcrypt-legacy
        zlib
      ];

      runtimeLibraryPath = lib.concatStringsSep ":" [
        "${pkgs.addDriverRunpath.driverLink}/lib"
        (lib.makeLibraryPath runtimeLibraries)
      ];

      runtimePath = lib.makeBinPath (with pkgs; [
        bash
        coreutils
        curl
        findutils
        gawk
        gnugrep
        gnused
        libnotify
        nodejs
        procps
        python3
        systemd
        util-linux
        xdg-utils
      ]);

      gsettingsDataDirs = lib.concatMapStringsSep ":" (
        package: lib.removeSuffix "/glib-2.0/schemas" (pkgs.glib.getSchemaPath package)
      ) [ pkgs.gsettings-desktop-schemas pkgs.gtk3 ];

      chatgpt = pkgs.stdenv.mkDerivation {
        pname = "chatgpt";
        version = "latest";
        src = chatgpt-deb;

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        # The explicit ELF audit below owns interpreters and RUNPATHs. Generic
        # fixups can undo the special ChatGPT PT_INTERP relocation.
        dontPatchELF = true;
        dontStrip = true;
        dontFixup = true;

        nativeBuildInputs = with pkgs; [
          bash
          coreutils
          dpkg
          makeWrapper
          nodejs
          patchelf
        ];

        installPhase = ''
          runHook preInstall

          package_root="$TMPDIR/package"
          mkdir -p "$package_root"
          dpkg-deb -x "$src" "$package_root"

          upstream_app="$package_root/usr/lib/chatgpt"
          test -x "$upstream_app/ChatGPT"
          test -x "$upstream_app/resources/codex"
          test -f "$package_root/usr/share/applications/chatgpt.desktop"
          test -f "$package_root/usr/share/pixmaps/chatgpt.png"

          node ${./nix/elf-runtime.cjs} validate-upstream \
            --root "$upstream_app" \
            --arch amd64 \
            --manifest ${./nix/elf-runtime-manifest.json}

          app="$out/lib/chatgpt"
          mkdir -p "$out/lib" "$out/share/applications" "$out/share/pixmaps"
          cp -a "$upstream_app" "$app"
          cp "$package_root/usr/share/applications/chatgpt.desktop" \
            "$out/share/applications/chatgpt.desktop"
          cp "$package_root/usr/share/pixmaps/chatgpt.png" \
            "$out/share/pixmaps/chatgpt.png"

          dynamic_linker="$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)"
          node ${./nix/elf-runtime.cjs} fix \
            --root "$app" \
            --arch amd64 \
            --dynamic-linker "$dynamic_linker" \
            --runtime-library-path "${runtimeLibraryPath}" \
            --patchelf "${pkgs.patchelf}/bin/patchelf" \
            --chatgpt-relocator ${./nix/relocate-elf-interpreter.cjs} \
            --shell "${pkgs.bash}/bin/bash" \
            --manifest ${./nix/elf-runtime-manifest.json}
          patchShebangs --build "$app"

          makeWrapper "$app/codex-launcher" "$out/bin/chatgpt" \
            --prefix PATH : "${runtimePath}" \
            --set-default ALSA_PLUGIN_DIR "${pkgs.pipewire}/lib/alsa-lib" \
            --run 'export XDG_DATA_DIRS="''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"' \
            --prefix XDG_DATA_DIRS : "${gsettingsDataDirs}" \
            --set-default BAMF_DESKTOP_FILE_HINT "$out/share/applications/chatgpt.desktop" \
            --set-default CODEX_CLI_PATH "$app/resources/codex" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-wayland-ime=true --wayland-text-input-version=3}}"

          node ${./nix/elf-runtime.cjs} audit \
            --root "$app" \
            --arch amd64 \
            --dynamic-linker "$dynamic_linker" \
            --runtime-library-path "${runtimeLibraryPath}" \
            --patchelf "${pkgs.patchelf}/bin/patchelf" \
            --manifest ${./nix/elf-runtime-manifest.json}
          node ${./nix/relocate-elf-interpreter.cjs} check \
            "$app/ChatGPT" "$dynamic_linker"

          runHook postInstall
        '';

        meta = {
          description = "ChatGPT by OpenAI";
          homepage = "https://developers.openai.com/codex/app";
          license = lib.licenses.unfree;
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

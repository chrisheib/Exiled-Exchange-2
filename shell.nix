# Warning: electron-overlay-window is using deprecated libs.
# It needs a fix to run on current npm:
#
# cd main
# npm i --ignore-scripts
# npm i -D patch-package
# npx patch-package electron-overlay-window
# npm i
#
# To create patch:
# In node_modules/electron-overlay-window/lib/addon.c:
#   replace 'status = napi_create_buffer(env, size, &img_data, &img_buffer);'
#   with 'status = napi_create_buffer(env, size, (void **)&img_data, &img_buffer);'
# npx patch-package electron-overlay-window

let
  pkgs = import <nixpkgs> { };

  buildInputs = with pkgs; [
    # Node tooling
    nodejs_20
    yarn
    pnpm

    # Python tooling
    python3
    # poetry is available at top-level `pkgs.poetry` in many nixpkgs, not under python.pkgs
    pkgs.poetry
    (python3.pkgs.pytest)

    # Native build tools (used by some native Node/Electron modules)
    pkg-config
    openssl
    gnumake
    cmake
    gcc
    binutils
    # Provide a system node-gyp to help with native builds
    # (pkgs.nodePackages.node-gyp)

    # X/GL libraries required for Electron and native modules
    libxkbcommon
    libGL
    xorg.libX11
    xorg.libxcb
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXtst
    xorg.libXt
    xorg.libXinerama
    xorg.libXfixes
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXScrnSaver
    xorg.libXrender

    nss
    nspr
    atk
    gtk3
    glib
    pango
    cairo
    gdk-pixbuf
    dbus
    cups
    alsa-lib
    electron-bin
  ];
in
pkgs.mkShell {
  inherit buildInputs;
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  shellHook = ''
    echo "Node: $(node --version)"
    echo "npm:  $(npm --version)"
    echo "yarn: $(yarn --version 2>/dev/null || echo 'not installed')"
    echo "pnpm: $(pnpm --version 2>/dev/null || echo 'not installed')"
    echo "Python: $(python --version)"
    # Ensure node-gyp and other native builds use the same Python
    export npm_config_python=$(which python)
    # When building native Electron modules, use Electron headers matching our electron version
    export npm_config_runtime=electron
    export npm_config_target=38.7.1
    export npm_config_disturl=https://electronjs.org/headers
    # export ELECTRON_BINARY="${pkgs.electron-bin}/bin/electron"

    export ELECTRON_BINARY="$PWD/.electron"
    cat > "$ELECTRON_BINARY" <<'EOF'
    #!/usr/bin/env bash
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath buildInputs}
    exec "${pkgs.electron}/bin/electron" "$@"
    EOF
    chmod +x "$ELECTRON_BINARY"
  '';
}

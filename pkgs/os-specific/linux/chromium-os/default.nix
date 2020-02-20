{ lib, newScope, fetchFromGitiles, symlinkJoin
, linux_4_19, makeLinuxHeaders, modemmanager
}:

let
  self = with self; {
    callPackage = newScope self;

    upstreamInfo = lib.importJSON ./upstream-info.json;

    chromiumos-overlay = (fetchFromGitiles
      upstreamInfo.components."chromiumos/overlays/chromiumos-overlay") // {
        passthru.updateScript = ./update.py;
      };

    common-mk = callPackage ./common-mk { };

    crosvm = callPackage ./crosvm { };

    dbus-properties = callPackage ./dbus-properties { };

    dbus-interfaces = symlinkJoin {
      name = "dbus-interfaces";
      paths = [ dbus-properties self.modemmanager modemmanager-next ];
      passthru.updateScript = ./update.py;
    };

    libbrillo = callPackage ./libbrillo { };

    libchrome = callPackage ./libchrome { };

    linux_4_19 = callPackage ../kernel/linux-cros.nix {
      inherit (linux_4_19) kernelPatches;
    };

    linux = self.linux_4_19;

    linuxHeaders = (makeLinuxHeaders {
      inherit (linux) version src;
    }).overrideAttrs ({ nativeBuildInputs, ... }: {
      # makeLinuxHeaders is designed for Linux 5.5, which has a
      # different header build system from 4.19, currently used by
      # Chromium OS.  When the Chromium OS kernel bumps to a new major
      # version, try removing this override to see if it's still
      # necessary.  If it builds without it, the override can go.
      buildPhase = ''
        make headers_install $makeFlags
      '';
    });

    minigbm = callPackage ./minigbm { };

    modemmanager = callPackage ./modem-manager {
      inherit modemmanager;
    };

    modemmanager-next = callPackage ./modem-manager/next.nix {
      inherit modemmanager;
    };

    modp_b64 = callPackage ./modp_b64 { };

    protofiles = callPackage ./protofiles { };

    sommelier = callPackage ./sommelier { };

    vm_protos = callPackage ./vm_protos { };
  };

in self // (with self; {
  inherit (upstreamInfo) version;
})

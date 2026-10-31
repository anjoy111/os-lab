{
  description = "Build, runtime, and analysis environments for embedded/Yocto development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.${system} = {

        # ============================================================
        # BUILD ENVIRONMENT
        #
        # Usage:
        #   nix develop .#build
        #
        # Contains tools required to:
        #   - Build C/C++ projects
        #   - Run CMake/Ninja builds
        #   - Run Python build scripts
        #   - Run Yocto/BitBake host tooling
        #   - Compile GTest-based test binaries
        # ============================================================

        build = pkgs.mkShell {
          name = "embedded-build";

          packages = with pkgs; [
            # C / C++ toolchain
            gcc
            gnumake
            binutils

            # Build system
            cmake
            ninja

            # Python
            python3
            python3Packages.pip
            python3Packages.setuptools
            python3Packages.wheel

            # Testing frameworks needed at compile time
            gtest
            catch2

            # General build tools
            git
            git-lfs
            pkg-config

            which
            file
            patch
            diffutils

            # Yocto / BitBake dependencies
            gawk
            chrpath
            cpio
            diffstat
            texinfo

            unzip
            zip
            xz
            zstd

            rsync

            wget
            curl

            # Compression tools commonly needed by Yocto
            gzip
            bzip2

            # Common utilities
            coreutils
            findutils
            gnugrep
            gnused
            util-linux

            # Useful debugging during builds
            strace
            lsof

            # Optional but useful
            bc
            ccache
          ];

          shellHook = ''
            echo ""
            echo "=============================================="
            echo " Embedded BUILD environment"
            echo "=============================================="
            echo ""

            echo "CMake : $(cmake --version | head -n 1)"
            echo "Ninja : $(ninja --version)"
            echo "Python: $(python --version)"

            echo ""
            echo "Yocto build host tools loaded."
            echo ""

            export PROJECT_ENV=build
          '';
        };

        # ============================================================
        # RUNTIME / TEST EXECUTION ENVIRONMENT
        #
        # Usage:
        #   nix develop .#runtime
        #
        # Contains tools required to:
        #   - Run QEMU
        #   - Execute already-built test binaries
        #   - Debug applications
        #   - Inspect binaries
        # ============================================================

        runtime = pkgs.mkShell {
          name = "embedded-runtime";

          packages = with pkgs; [
            # QEMU
            qemu

            # Debugging
            gdb
            gdbgui

            # Binary inspection
            binutils
            elfutils
            file

            # Runtime diagnostics
            strace
            ltrace
            lsof

            # Memory debugging
            valgrind

            # Performance tools
            perf

            # General utilities
            git
            coreutils
            findutils

            # Networking
            iproute2
            iputils
            nettools
          ];

          shellHook = ''
            echo ""
            echo "=============================================="
            echo " Embedded RUNTIME environment"
            echo "=============================================="
            echo ""

            echo "QEMU:"
            qemu-system-x86_64 --version | head -n 1 || true

            echo ""
            echo "Runtime and test tools loaded."
            echo ""

            export PROJECT_ENV=runtime
          '';
        };

        # ============================================================
        # STATIC ANALYSIS ENVIRONMENT
        #
        # Usage:
        #   nix develop .#analysis
        #
        # Contains tools required to:
        #   - Format code
        #   - Lint/static-analyze C/C++ code
        # ============================================================

        analysis = pkgs.mkShell {
          name = "embedded-analysis";

          packages = with pkgs; [
            clang-tools # clang-format, clang-tidy
            cppcheck
            include-what-you-use
          ];

          shellHook = ''
            echo ""
            echo "=============================================="
            echo " Embedded ANALYSIS environment"
            echo "=============================================="
            echo ""

            export PROJECT_ENV=analysis
          '';
        };

        # ============================================================
        # DEFAULT ENVIRONMENT
        #
        # Convenience:
        #   nix develop
        #
        # enters the build environment.
        # ============================================================

        default = self.devShells.${system}.build;
      };
    };
}

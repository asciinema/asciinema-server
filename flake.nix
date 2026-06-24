{
  description = "asciinema server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pname = "asciinema-server";
        pkgs = nixpkgs.legacyPackages.${system};

        beamPackages = pkgs.beam.packages.erlang_28.extend (
          _: prev: {
            elixir = prev.elixir_1_19;
          }
        );

        nifs = pkgs.rustPlatform.buildRustPackage {
          pname = "${pname}-nifs";
          version = "1.0.0";
          src = ./native;

          cargoLock = {
            lockFile = ./native/Cargo.lock;
          };
        };

        npmDeps = pkgs.buildNpmPackage {
          pname = "${pname}-node-modules";
          version = "1.0.0";
          src = ./assets;
          npmDepsHash = "sha256-Vb/A1LGHVIGmz+mHpB10GiOmzB820yDKtrQTzTZsYhA=";
          dontNpmBuild = true;

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/
          '';
        };
      in
      {
        packages.default = beamPackages.mixRelease rec {
          inherit pname;
          version = "1.0.0";
          src = ./.;

          mixFodDeps = beamPackages.fetchMixDeps {
            pname = "${pname}-mix-deps";
            inherit src version;
            hash = "sha256-h/m2E76u2rej2XT8E09aWl74rsvPz6gNeUKquLYw+IU=";
          };

          preConfigure = ''
            cat >>config/config.exs <<EOF
            config :asciinema, Asciinema.Vt, skip_compilation?: true
            config :asciinema, Asciinema.Fts, skip_compilation?: true
            config :asciinema, Asciinema.SvgRaster, skip_compilation?: true
            config :esbuild, path: "${pkgs.esbuild}/bin/esbuild"
            config :tailwind, path: "${pkgs.tailwindcss_3}/bin/tailwindcss"
            EOF

            mkdir -p priv/native
            cp ${nifs}/lib/libvt.so priv/native/vt.so
            cp ${nifs}/lib/libfts.so priv/native/fts.so
            cp ${nifs}/lib/libsvg_raster.so priv/native/svg_raster.so
          '';

          preInstall = ''
            ln -sf ${npmDeps}/node_modules assets/node_modules
            mix assets.deploy
          '';

          buildInputs = with pkgs; [
            librsvg
            pngquant
            fd
          ];
        };

        devShells.default = pkgs.mkShell {
          packages =
            with pkgs;
            [
              beamPackages.elixir
              beamPackages.elixir-ls
              nodejs_24
              cargo
              rustc
              rustfmt
              rust-analyzer
              rustPackages.clippy
              shellcheck
              imagemagick
              playwright-driver.browsers
            ]
            ++ self.packages.${system}.default.buildInputs
            ++ lib.optionals stdenv.isLinux [ inotify-tools ];

          shellHook = ''
            # this allows mix to work on the local directory
            mkdir -p .nix-mix .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex

            # make hex from Nixpkgs available
            # `mix local.hex` will install hex into MIX_HOME and should take precedence
            export MIX_PATH="${beamPackages.hex}/lib/erlang/lib/hex/ebin"
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            # keep shell history in iex
            export ERL_AFLAGS="-kernel shell_history enabled"

            alias serve='iex -S mix phx.server';
          '';

          # Playwright browsers pinned via the flake — no manual `playwright install`.
          PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
        };

        formatter = pkgs.nixfmt-tree;
      }
    )
    // {
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.asciinema-server;
          user = "asciinema-server";
          pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          # Render the env-var bag: bools -> "true"/"false", ints -> decimal;
          # a null value drops the variable.
          renderedEnvironment = lib.mapAttrs (_: v: if lib.isBool v then lib.boolToString v else toString v) (
            lib.filterAttrs (_: v: v != null) cfg.environment
          );
        in
        {
          options.services.asciinema-server = {
            enable = lib.mkEnableOption "asciinema-server";

            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = "/run/secrets/asciinema-server.env";

              description = ''
                Path to an environment file, kept outside the Nix store,
                holding secrets as `KEY=value` lines, e.g.
                `DATABASE_URL=ecto://user:pass@host/db`. Passed to the unit as
                systemd `EnvironmentFile=`. Use it for anything sensitive
                (DATABASE_URL, SECRET_KEY_BASE, SMTP_PASSWORD, S3 keys) so it is
                never written to the world-readable store. Typically provided by
                sops-nix/agenix or a hand-managed root-owned 0400 file.
              '';
            };

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/asciinema";
              description = ''
                Directory for the service's local state, created and owned by the
                asciinema-server user. Uploads are stored under
                `<dataDir>/uploads` when the local file store is used, and the
                generated SECRET_KEY_BASE is kept here.
              '';
            };

            environment = lib.mkOption {
              type =
                with lib.types;
                attrsOf (
                  nullOr (oneOf [
                    bool
                    int
                    str
                  ])
                );
              default = { };

              example = {
                URL_HOST = "asciinema.example.com";
                URL_SCHEME = "https";
                PORT = 4000;
                BIND_ALL = true;
              };

              description = ''
                Non-secret environment variables for the server, merged into
                the systemd unit. The release reads its runtime configuration
                from the environment (see `config/runtime.exs`), e.g. URL_HOST,
                URL_SCHEME, PORT, BIND_ALL, S3_* and SMTP_*.

                Values may be strings, integers or booleans; integers and
                booleans become strings, and a `null` value drops the variable.

                Put secrets in `environmentFile` instead. The module-managed
                HOME, DATA_DIR, CACHE_PATH and RELEASE_TMP take precedence.
              '';
            };
          };

          config = lib.mkIf cfg.enable {
            users.users.${user} = {
              isSystemUser = true;
              group = user;
              home = cfg.dataDir;
            };

            users.groups.${user} = { };

            systemd.services.asciinema-server = {
              wantedBy = [ "multi-user.target" ];
              wants = [ "network-online.target" ];
              after = [
                "network-online.target"
                "postgresql.service"
              ];

              # Runtime tools the app shells out to by bare name: rsvg-convert
              # (librsvg) and pngquant for SVG->PNG rendering, fd for file cache
              # cleanup, which is used by svg2png.sh to detect timeout/pngquant.
              path = [
                pkgs.librsvg
                pkgs.pngquant
                pkgs.fd
                pkgs.which
              ];

              script = ''
                [ -n "$SECRET_KEY_BASE" ] || export SECRET_KEY_BASE="$(cat "$HOME/secret_key_base")"
                [ -n "$RELEASE_COOKIE" ] || export RELEASE_COOKIE="$(cat "$HOME/release_cookie")"
                ${pkg}/bin/server
              '';

              environment = {
                # Bind epmd to loopback so distributed Erlang isn't exposed on
                # the network; override via `environment` for multi-host
                # clustering.
                ERL_EPMD_ADDRESS = "127.0.0.1";
              }
              // renderedEnvironment
              // {
                HOME = cfg.dataDir;
                DATA_DIR = cfg.dataDir;
                CACHE_PATH = "/var/cache/asciinema";
                # The release writes its evaluated runtime config (and a
                # pipe/log) here; the default $RELEASE_ROOT/tmp is in the
                # read-only Nix store, so point it at a writable tmpfs dir.
                RELEASE_TMP = "/run/asciinema";
              };

              serviceConfig = {
                User = user;
                Group = user;
                Restart = "on-failure";
                RestartSec = 5;
                RuntimeDirectory = "asciinema";
                CacheDirectory = "asciinema";
                EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

                # Light sandboxing. The data dir is the only extra writable path;
                # the Runtime/Cache dirs are made writable by systemd already.
                # Deliberately no MemoryDenyWriteExecute or SystemCallFilter, which
                # break the Erlang JIT and schedulers.
                ProtectSystem = "strict";
                ReadWritePaths = [ cfg.dataDir ];
                ProtectHome = true;
                PrivateTmp = true;
                NoNewPrivileges = true;

                # Generate and persist SECRET_KEY_BASE and the Erlang
                # distribution cookie in the data dir (unless given via
                # environmentFile) so they survive restarts and stay out of
                # the store.
                ExecStartPre = pkgs.writeShellScript "asciinema-server-secrets" ''
                  umask 077
                  test -n "$SECRET_KEY_BASE" || test -s "$HOME/secret_key_base" ||
                    tr -dc A-Za-z0-9 </dev/urandom | head -c 64 >"$HOME/secret_key_base"
                  test -n "$RELEASE_COOKIE" || test -s "$HOME/release_cookie" ||
                    tr -dc A-Za-z0-9 </dev/urandom | head -c 32 >"$HOME/release_cookie"
                '';
              };
            };

            systemd.tmpfiles.rules = [
              "d ${cfg.dataDir} 0750 ${user} ${user} - -"
            ];
          };
        };
    };
}

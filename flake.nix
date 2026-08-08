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

        # beam_minimal = no wx GUI apps and no systemd linkage in epmd; the
        # latter would otherwise pull the full systemd closure (~120 MB) into
        # every release via a single libsystemd reference.
        beamPackages = pkgs.beam_minimal.packages.erlang_28.extend (
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

        mixShellHook = ''
          # this allows mix to work on the local directory
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex

          # make hex and rebar3 from Nixpkgs available so mix doesn't
          # download them
          # `mix local.hex` will install hex into MIX_HOME and should take precedence
          export MIX_PATH="${beamPackages.hex}/lib/erlang/lib/hex/ebin"
          export MIX_REBAR3="${beamPackages.rebar3}/bin/rebar3"
          export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

          export MIX_ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild"
        '';

        npmDeps = pkgs.buildNpmPackage {
          pname = "${pname}-node-modules";
          version = "1.0.0";
          src = ./assets;
          npmDepsHash = "sha256-cUan/gu8VCOjb8Ghg0+Cwp2BdKmWg8S4tZOQ8woZ75g=";
          dontNpmBuild = true;

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/
          '';
        };
        # Tools the app shells out to at runtime: rsvg-convert (librsvg) and
        # pngquant for SVG->PNG rendering, fd for file cache cleanup, plus
        # `which` and `grep`, used by priv/svg2png.sh to probe for
        # timeout/pngquant. The release embeds these on PATH via env.sh (see
        # postInstall), so the module and image need no extra provisioning.
        runtimeTools = with pkgs; [
          librsvg
          pngquant
          fd
          which
          gnugrep
        ];

        # App version shown on /about; deploy pipelines override it with:
        # VERSION=... nix build --impure .#image
        appVersion =
          let v = builtins.getEnv "VERSION";
          in if v != "" then v else (self.shortRev or self.dirtyShortRev or "dev");

        server = beamPackages.mixRelease rec {
          inherit pname;
          version = "1.0.0";
          src = ./.;

          VERSION = appVersion;

          mixFodDeps = beamPackages.fetchMixDeps {
            pname = "${pname}-mix-deps";
            inherit src version;
            hash = "sha256-LHCM4d6OEeB6ywNdVyb1Z3qTLQbX2Eh5kI/0v/fbAys=";
          };

          preConfigure = ''
            cat >>config/config.exs <<EOF
            config :asciinema, Asciinema.Vt, skip_compilation?: true
            config :asciinema, Asciinema.Fts, skip_compilation?: true
            config :asciinema, Asciinema.SvgRaster, skip_compilation?: true
            config :esbuild, path: "${pkgs.esbuild}/bin/esbuild"
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

          nativeBuildInputs = [ pkgs.removeReferencesTo ];

          # Scrub the build-time-only esbuild store path baked by preConfigure
          # so it doesn't bloat the runtime closure; fail if it reappears.
          #
          # Then make the release self-contained: env.sh (sourced by every
          # bin/* command) gets the runtime tools on PATH plus the font setup
          # for SVG->PNG rendering. The embedded store paths pull the tools
          # and fonts into the closure, so consumers need no provisioning.
          postInstall = ''
            find $out/releases -name sys.config \
              -exec remove-references-to -t ${pkgs.esbuild} {} +

            for env_sh in $out/releases/*/env.sh; do
              printf '\n%s\n%s\n%s\n' \
                'export PATH="${pkgs.lib.makeBinPath runtimeTools}:$PATH"' \
                'export FONTCONFIG_FILE="''${FONTCONFIG_FILE:-${fontsConf}}"' \
                'export RSVG_FONT_FAMILY="''${RSVG_FONT_FAMILY:-Dejavu Sans Mono}"' \
                >>"$env_sh"
            done
          '';

          disallowedReferences = [ pkgs.esbuild ];
        };

        fontsConf = pkgs.makeFontsConf {
          fontDirectories = [ pkgs.dejavu_fonts ];
        };

        # Generates a persistent node cookie in the data dir on first boot
        # (nixpkgs strips the baked releases/COOKIE); the release scripts
        # read it via the env.sh fallback.
        imageEntrypoint = pkgs.writeShellScriptBin "image-entrypoint" ''
          set -eu

          if [ -z "''${RELEASE_COOKIE:-}" ]; then
            # mirror env.sh's data dir resolution
            if [ -n "''${DATA_DIR:-}" ]; then
              data_dir=$DATA_DIR
            elif [ -d /var/opt/asciinema/uploads ]; then
              data_dir=/var/opt/asciinema
            else
              data_dir=/var/lib/asciinema
            fi

            if [ ! -s "$data_dir/release_cookie" ]; then
              (umask 027; od -An -tx1 -N32 /dev/urandom | tr -d ' \n' > "$data_dir/release_cookie")
            fi
          fi

          exec "$@"
        '';
      in
      {
        packages = {
          default = server;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          # OCI image, a drop-in replacement for the Dockerfile-built one
          image = pkgs.dockerTools.streamLayeredImage {
            name = "asciinema-server";
            tag = "latest";

            contents = with pkgs; [
              server
              imageEntrypoint
              bashInteractive
              coreutils
              tini
              cacert
              tzdata
            ];

            fakeRootCommands = ''
              mkdir -p tmp opt var/lib/asciinema var/cache/asciinema
              chmod 1777 tmp
              # OTP's OS trust store only searches canonical paths; without
              # this link HTTPS via :httpc fails with :no_cacerts_found
              mkdir -p etc/ssl/certs
              ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
              # /opt/app mirrors the legacy image layout (documented bind mounts)
              ln -s ${server} opt/app
              cp ${./.iex.exs} .iex.exs
              # support running as an arbitrary uid (gid 0), like the legacy image
              chgrp -R 0 var/lib/asciinema var/cache/asciinema
              chmod -R g=u var/lib/asciinema var/cache/asciinema
            '';

            config = {
              Entrypoint = [
                "${pkgs.tini}/bin/tini"
                "--"
                "${imageEntrypoint}/bin/image-entrypoint"
              ];
              Cmd = [ "/opt/app/bin/server" ];
              # legacy (Docker) image parity
              WorkingDir = "/opt/app";
              ExposedPorts."4000/tcp" = { };

              Env = [
                "PORT=4000"
                "ADMIN_BIND_ALL=1"
                "DATABASE_URL=postgresql://postgres@postgres/postgres"
                "CACHE_PATH=/var/cache/asciinema"
                # static Env so docker exec'd commands see it too
                "RELEASE_TMP=/tmp"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "LANG=C.UTF-8"
                "TZDIR=/share/zoneinfo"
                "PATH=/opt/app/bin:/bin"
              ];
            };
          };
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
            ++ runtimeTools
            ++ lib.optionals stdenv.isLinux [ inotify-tools ];

          shellHook = ''
            ${mixShellHook}

            # keep shell history in iex
            export ERL_AFLAGS="-kernel shell_history enabled"

            alias serve='iex -S mix phx.server';
          '';

          # Playwright browsers pinned via the flake — no manual `playwright install`.
          PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
        };

        # Lean shell for CI: toolchains and test-time tools only, no dev extras
        # (no Playwright browsers, editor tooling, etc).
        devShells.ci = pkgs.mkShell {
          packages =
            with pkgs;
            [
              beamPackages.elixir
              nodejs_24
              cargo
              rustc
              rustPackages.clippy
              imagemagick
            ]
            ++ runtimeTools;

          shellHook = mixShellHook;
        };

        formatter = pkgs.nixfmt-tree;

        checks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          # Boots a VM with the module (local PostgreSQL on by default),
          # building the release, running migrations and serving a request.
          nixos-module = pkgs.testers.runNixOSTest {
            name = "asciinema-server-module";

            nodes.machine =
              { pkgs, ... }:
              {
                imports = [ self.nixosModules.default ];

                services.asciinema = {
                  enable = true;

                  environment = {
                    URL_HOST = "localhost";
                    PORT = 4000;
                    BIND_ALL = true;
                  };
                };

                environment.systemPackages = [ pkgs.curl ];
                virtualisation.memorySize = 2048;
              };

            testScript = ''
              machine.wait_for_unit("postgresql.service")
              machine.wait_for_unit("asciinema-server.service")
              machine.wait_for_open_port(4000)
              machine.succeed("curl -sfL http://127.0.0.1:4000/ | grep -qi asciinema")

              # attach commands work with zero cookie config: env.sh reads
              # the cookie ExecStartPre persisted in the data dir
              machine.succeed("${server}/bin/asciinema rpc 'IO.puts(:rpc_ok)' | grep -q rpc_ok")
              machine.succeed("${server}/bin/send-test-email test@example.com | grep -q ok")
              machine.succeed("stat -c %a:%U /var/lib/asciinema/release_cookie | grep -qx 600:asciinema")

              # the cookie survives service restarts, so attach keeps working
              machine.succeed("cp /var/lib/asciinema/release_cookie /root/cookie.before")
              machine.succeed("systemctl restart asciinema-server")
              machine.wait_for_open_port(4000)
              machine.succeed("cmp /root/cookie.before /var/lib/asciinema/release_cookie")
              machine.succeed("${server}/bin/asciinema rpc 'IO.puts(:rpc_ok)' | grep -q rpc_ok")
            '';
          };

          # Boots the actual OCI image under podman - tini, entrypoint and
          # baked Env, which the module check cannot see.
          oci-image = pkgs.testers.runNixOSTest {
            name = "asciinema-server-oci-image";

            nodes.machine =
              { pkgs, ... }:
              let
                customExs = pkgs.writeText "custom.exs" ''
                  import Config
                  config :asciinema, oci_check_probe: "loaded"
                '';
              in
              {
                services.postgresql = {
                  enable = true;
                  # the container reaches the host database over loopback
                  authentication = pkgs.lib.mkForce ''
                    local all all trust
                    host all all 127.0.0.1/32 trust
                    host all all ::1/128 trust
                  '';
                  ensureDatabases = [ "asciinema" ];
                  ensureUsers = [
                    {
                      name = "asciinema";
                      ensureDBOwnership = true;
                    }
                  ];
                };

                virtualisation.oci-containers = {
                  backend = "podman";

                  containers.asciinema = {
                    # both must match the streamLayeredImage name/tag
                    image = "asciinema-server:latest";
                    imageStream = self.packages.${pkgs.stdenv.hostPlatform.system}.image;
                    extraOptions = [ "--network=host" ];
                    volumes = [ "${customExs}:/opt/app/etc/custom.exs" ];

                    environment = {
                      DATABASE_URL = "postgresql://asciinema@127.0.0.1/asciinema";
                      SECRET_KEY_BASE = "oci-check-secret-key-base-oci-check-secret-key-base-oci-check-64";
                      URL_HOST = "localhost";
                    };
                  };
                };

                environment.systemPackages = [ pkgs.curl ];
                virtualisation.memorySize = 2048;
                virtualisation.diskSize = 4096;
              };

            testScript = ''
              machine.wait_for_unit("postgresql.service")
              machine.wait_for_unit("podman-asciinema.service")
              machine.wait_for_open_port(4000)
              machine.succeed("curl -sfL http://127.0.0.1:4000/ | grep -qi asciinema")

              # attach commands prove the entrypoint/env.sh cookie contract
              machine.succeed("podman exec asciinema /opt/app/bin/asciinema rpc 'IO.puts(:rpc_ok)' | grep -q rpc_ok")
              machine.succeed("podman exec asciinema /opt/app/bin/send-test-email test@example.com | grep -q ok")
              machine.succeed("podman exec asciinema stat -c %a /var/lib/asciinema/release_cookie | grep -qx 640")

              # regression guard: OTP finds the CA bundle at the canonical path
              certs = machine.succeed("podman exec asciinema /opt/app/bin/asciinema eval 'IO.puts(length(:public_key.cacerts_get()))'")
              assert int(certs.strip()) > 0, f"no CA certificates loaded: {certs}"

              # the custom.exs bind mount reaches the config provider
              machine.succeed("podman exec asciinema /opt/app/bin/asciinema rpc 'IO.puts(Application.get_env(:asciinema, :oci_check_probe))' | grep -qx loaded")

              # the entrypoint provisions the cookie for command overrides too
              machine.succeed("podman run --rm localhost/asciinema-server:latest /opt/app/bin/asciinema version | grep -q asciinema")
            '';
          };
        };
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
          cfg = config.services.asciinema;
          user = "asciinema";
          pkg = cfg.package;

          # Render the env-var bag: bools -> "true"/"false", ints -> decimal;
          # a null value drops the variable.
          renderedEnvironment = lib.mapAttrs (_: v: if lib.isBool v then lib.boolToString v else toString v) (
            lib.filterAttrs (_: v: v != null) cfg.environment
          );
        in
        {
          options.services.asciinema = {
            enable = lib.mkEnableOption "asciinema server";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "asciinema-server.packages.\${pkgs.stdenv.hostPlatform.system}.default";

              description = ''
                Package providing the asciinema server release. The package must
                expose `bin/server`, which runs migrations and starts the
                Phoenix server, and must be self-contained like the default
                package: the service provides no PATH, so the release itself
                has to supply the tools it shells out to (rsvg-convert,
                pngquant, fd) and its font configuration - see the env.sh
                setup in the server derivation.
              '';
            };

            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = "/run/secrets/asciinema.env";

              description = ''
                Path to an environment file, kept outside the Nix store,
                holding secrets as `KEY=value` lines, e.g.
                `DATABASE_URL=ecto://user:pass@host/db`. Passed to the unit as
                systemd `EnvironmentFile=`. Use it for anything sensitive
                (DATABASE_URL, SECRET_KEY_BASE, SMTP_PASSWORD, S3 keys) so it is
                never written to the world-readable store. Typically provided by
                sops-nix/agenix or a hand-managed root-owned 0400 file.

                systemd applies this after the inline `environment`, so a
                variable set in both places takes its value from here. If you
                set DATABASE_URL here, also set `database.createLocally = false`.
              '';
            };

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/asciinema";

              description = ''
                Directory for the service's local state, created and owned by the
                asciinema user. Uploads are stored under `<dataDir>/uploads`
                when the local file store is used, and the generated
                SECRET_KEY_BASE is kept here.
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

                Put secrets in `environmentFile` instead; systemd applies it
                after this, so a variable set in both places takes its value
                from `environmentFile`.
              '';
            };

            database.createLocally = lib.mkOption {
              type = lib.types.bool;
              default = true;

              description = ''
                Whether to provision a local PostgreSQL server for the
                asciinema server. Enabled by default: the module turns on
                services.postgresql, creates the ${user} role and database,
                and points the app at them over the /run/postgresql socket with
                peer authentication, managing DATABASE_URL for you. If
                PostgreSQL is already enabled on the host, the ${user} role and
                database are simply added to it. While enabled the
                module owns DATABASE_URL, so don't set your own. Set to false to
                bring your own database instead and provide DATABASE_URL
                yourself (via environmentFile).
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
              # When provisioning locally, order after postgresql-setup.service
              # — the oneshot that runs ensureDatabases/ensureUsers — so the
              # role and database exist before migrations run. It already orders
              # after postgresql.service itself.
              requires = lib.optional cfg.database.createLocally "postgresql-setup.service";

              after = [
                "network-online.target"
              ]
              ++ lib.optional cfg.database.createLocally "postgresql-setup.service";

              script = ''
                [ -n "$SECRET_KEY_BASE" ] || export SECRET_KEY_BASE="$(cat "$HOME/secret_key_base")"
                ${pkg}/bin/server
              '';

              environment = {
                # Keep epmd on its default interfaces so rpc/remote can reach
                # it through the node hostname; the firewall keeps distribution private.
              }
              // renderedEnvironment
              // lib.optionalAttrs cfg.database.createLocally {
                # Local PostgreSQL over its unix socket with peer auth;
                # socket_dir makes Postgrex use the socket and ignore the host.
                DATABASE_URL = "ecto://${user}@localhost/${user}?socket_dir=/run/postgresql";
              }
              // {
                HOME = cfg.dataDir;
                DATA_DIR = cfg.dataDir;
                CACHE_PATH = "/var/cache/asciinema";

                # the default $RELEASE_ROOT/tmp is in the read-only nix store
                RELEASE_TMP = "/run/asciinema";
              };

              serviceConfig = {
                User = user;
                Group = user;
                Restart = "on-failure";
                RestartSec = 5;
                RuntimeDirectory = "asciinema";
                RuntimeDirectoryMode = "0700";
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
                    tr -dc A-Za-z0-9 </dev/urandom 2>/dev/null | head -c 64 >"$HOME/secret_key_base"
                  test -n "$RELEASE_COOKIE" || test -s "$HOME/release_cookie" ||
                    tr -dc A-Za-z0-9 </dev/urandom 2>/dev/null | head -c 32 >"$HOME/release_cookie"
                '';
              };
            };

            systemd.tmpfiles.rules = [
              "d ${cfg.dataDir} 0750 ${user} ${user} - -"
            ];

            services.postgresql = lib.mkIf cfg.database.createLocally {
              enable = true;
              ensureDatabases = [ user ];

              ensureUsers = [
                {
                  name = user;
                  ensureDBOwnership = true;
                }
              ];
            };
          };
        };
    };
}

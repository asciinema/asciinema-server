{
  description = "asciinema server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        otp = pkgs.beam.packages.erlang_25;

        vt_nif = pkgs.rustPlatform.buildRustPackage {
          pname = "vt_nif";
          version = "1.0.0";
          # FIXME: Where the Rust code lives. For NIFs, this is usually native/my-rust-src
          src = builtins.path { path = ./native/vt_nif; };
          # A hash that ensures we're getting the right src.
          # Get this hash by running `nix hash path native/my-rust-src`
          # Nix will attempt to verify this when building and tell you the hash it got vs what it expected
          cargoHash = "sha256-OkAxM5fOmU7v3RdTAC8cpdgI9o0j/R56+9em5sYHDgU=";
        };
        nodeDependencies = pkgs.importNpmLock.buildNodeModules {
          npmRoot = ./assets/.;
          nodejs = pkgs.nodejs;
        };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            otp.elixir_1_14
            otp.elixir-ls
            nodejs_18
            (rust-bin.stable."1.78.0".default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
            inotify-tools
            librsvg
          ];

          shellHook = ''
            # this allows mix to work on the local directory
            mkdir -p .nix-mix .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex

            # make hex from Nixpkgs available
            # `mix local.hex` will install hex into MIX_HOME and should take precedence
            export MIX_PATH="${otp.hex}/lib/erlang/lib/hex/ebin"
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            # keep shell history in iex
            export ERL_AFLAGS="-kernel shell_history enabled"
            export PORT=8000
            alias serve='iex -S mix phx.server';
          '';
        };

        packages.default = otp.mixRelease rec {
          src = builtins.path { path = ./.; };
          pname = "asciinema-server";
          version = "1.0.0";

          mixFodDeps = otp.fetchMixDeps {
            pname = "mix-deps-${pname}";
            inherit src version;
            hash = "sha256-NoyG6g/muCAte5RNFVFNs7vP5IDGuys/ALZSuC/MVdw=";
            mixEnv = "";
          };

          MIX_PATH = "${otp.hex}/lib/erlang/lib/hex/ebin";

          nativeBuildInputs = with pkgs; [ inotify-tools librsvg nodejs ];

          preConfigure = ''
            mkdir -p priv/native
            cp ${vt_nif}/lib/libvt_nif.so priv/native/

            substituteInPlace lib/asciinema/vt.ex --replace "crate: :vt_nif" """
                crate: \"vt_nif\",
                skip_compilation?: true,
                load_from: {:asciinema, \"priv/native/libvt_nif\"}
                \

            """
          '';

          postBuild = ''
            mkdir -p $out/assets
            ln -sf ${nodeDependencies}/node_modules ./assets/
            export PATH=$(pwd)/assets/node_modules/.bin/:$PATH
            export NODE_PATH=$(pwd)/assets/node_modules:$NODE_PATH
            npm run deploy --prefix ./assets

            mix phx.digest --no-deps-check
          '';
        };

        nixosModules.default = { config, lib, pkgs, ... }:
          let cfg = config.services.asciinema-server;
          in {
            options.services.asciinema-server = {
              enable = lib.mkEnableOption "Enable the asciinema-server service";
              port = lib.mkOption {
                type = lib.types.int;
                default = 4000;
              };
              dbUser = lib.mkOption {
                type = lib.types.str;
                default = "asciinema_server";
              };
              dbPassword = lib.mkOption {
                type = lib.types.str;
                default = "asciinema_server";
              };
              secretKeyBase = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              releaseCookie = lib.mkOption {
                type = lib.types.str;
                default = "release-cookie";
              };
              uploadSizeLimit = lib.mkOption {
                type = lib.types.str;
                default = "8000000";
              };
            };
            config = lib.mkIf cfg.enable {
              services.postgresql = {
                enable = true;
                ensureUsers = [{
                  name = cfg.dbUser;
                  ensureDBOwnership = true;
                }];
                ensureDatabases = [ "asciinema_server" ];
              };
              systemd.services.postgresql.postStart = let
                password_file_path = config.sops.secrets.POSTGRES_PASSWORD.path;
              in ''
                $PSQL -tA <<'EOF'
                  DO $$
                  DECLARE password TEXT;
                  BEGIN
                    password := '${cfg.dbPassword}';
                    EXECUTE format('ALTER ROLE "${cfg.dbUser}" WITH PASSWORD '''%s''';', password);
                  END $$;
                EOF
              '';

              systemd.services."asciinema-server" = {
                wantedBy = [ "multi-user.target" ];

                serviceConfig = let pkg = self.packages.${pkgs.system}.default;
                in {
                  Environment = "PORT=${
                      builtins.toString cfg.port
                    } DATABASE_URL=postgres://${cfg.dbUser}:${cfg.dbPassword}@127.0.0.1/asciinema_server SECRET_KEY_BASE=${cfg.secretKeyBase} RELEASE_COOKIE=${cfg.releaseCookie} UPLOAD_SIZE_LIMIT=${cfg.uploadSizeLimit";
                  ExecStart = "${pkg}/bin/server";
                  WorkingDirectory = "${pkg}/";
                };
              };
            };
          };

      }) // {
        nixosConfigurations.container = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.x86_64-linux.default
            ({ pkgs, config, ... }: {
              boot.isContainer = true;
              networking.hostName = "asciinema-server";
              networking.firewall.allowedTCPPorts =
                [ config.services.asciinema-server.port ];
              services.asciinema-server.enable = true;
              services.asciinema-server.secretKeyBase =
                "2yISEaoQUC1Pd8sHWiJfHpUwwrVHXLFJVIlhtCAAKV5qvBK4QPia0tqQwxWlU8EAAAAAAAAAAAAAAAAAAA";

            })
          ];
        };
      };
}

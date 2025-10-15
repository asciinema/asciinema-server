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
        beamPackages = pkgs.beam.packages.erlang_26;

        vtNif = pkgs.rustPlatform.buildRustPackage {
          pname = "${pname}-vt-nif";
          version = "1.0.0";
          src = ./native/vt_nif;

          cargoLock = {
            lockFile = ./native/vt_nif/Cargo.lock;
          };
        };

        npmDeps = pkgs.buildNpmPackage {
          pname = "${pname}-node-modules";
          version = "1.0.0";
          src = ./assets;
          npmDepsHash = "sha256-0eex36+jrn+PY23KEjkSZMMYUYGPjGVAFdUeYUZzhq8=";
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
          elixir = beamPackages.elixir_1_18;

          mixFodDeps = beamPackages.fetchMixDeps {
            pname = "${pname}-mix-deps";
            inherit src version;
            hash = "sha256-8Am3KLa6TKh3snV/D58Q8X/qzIqJwPT29imf5datVUw=";
          };

          preConfigure = ''
            cat >>config/config.exs <<EOF
            config :asciinema, Asciinema.Vt, skip_compilation?: true
            config :esbuild, path: "${pkgs.esbuild}/bin/esbuild"
            config :tailwind, path: "${pkgs.tailwindcss_3}/bin/tailwindcss"
            EOF

            mkdir -p priv/native
            cp ${vtNif}/lib/libvt_nif.so priv/native/
          '';

          preInstall = ''
            ln -sf ${npmDeps}/node_modules assets/node_modules
            mix assets.deploy
          '';

          buildInputs = with pkgs; [
            librsvg
            pngquant
          ];

          removeCookie = false;
        };

        devShells.default = pkgs.mkShell {
          packages =
            with pkgs;
            [
              beamPackages.elixir_1_18
              beamPackages.elixir-ls
              nodejs_20
              cargo
              rustc
              rustfmt
              rust-analyzer
              rustPackages.clippy
              inotify-tools
              shellcheck
            ]
            ++ self.packages.${system}.default.buildInputs;

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
        };
      }
    );
}

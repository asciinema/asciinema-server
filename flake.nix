{
  description = "asciinema server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        otp = pkgs.beam.packages.erlang_25;
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            otp.elixir_1_14
            otp.elixir-ls
            nodejs_18
            (rust-bin.stable."1.78.0".default.override { extensions = [ "rust-src" "rust-analyzer" ]; })
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

            alias serve='iex -S mix phx.server';
          '';
        };
      }
    );
}

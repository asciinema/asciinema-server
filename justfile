default: serve

serve:
  iex -S mix phx.server

test:
  mix test

format:
  mix format
  cd native/vt && cargo fmt
  cd native/fts && cargo fmt
  cd native/svg_raster && cargo fmt

# build the OCI image with nix
image:
  nix build .#image

# build the OCI image and load it into docker
image-docker: image
  ./result | docker load

# build the OCI image and load it into podman
image-podman: image
  ./result | podman load

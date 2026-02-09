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

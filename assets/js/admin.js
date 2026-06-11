import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { create as createPlayer } from "asciinema-player";

document.addEventListener("submit", (event) => {
  const message = event.target?.getAttribute?.("data-confirm");
  if (message && !window.confirm(message)) {
    event.preventDefault();
  }
});

// ws(s) sources play live via the websocket driver
function mountPlayer() {
  const el = document.getElementById("player");
  if (!el || !el.dataset.src || el.dataset.mounted) return;
  el.dataset.mounted = "1";
  const src = el.dataset.src;
  const playerSrc =
    src.startsWith("ws://") || src.startsWith("wss://")
      ? { driver: "websocket", url: src }
      : src;
  createPlayer(playerSrc, el, { fit: "width" });
}

document.addEventListener("DOMContentLoaded", mountPlayer);

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();
window.liveSocket = liveSocket;

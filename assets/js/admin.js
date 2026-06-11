import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { createPlayer } from "./player";

document.addEventListener("submit", (event) => {
  const message = event.target?.getAttribute?.("data-confirm");
  if (message && !window.confirm(message)) {
    event.preventDefault();
  }
});

// ws(s) sources play live via the websocket driver
async function mountPlayer() {
  const el = document.getElementById("player");
  if (!el || !el.dataset.src || el.dataset.mounted) return;
  el.dataset.mounted = "1";

  const src = el.dataset.src;
  const isLive = src.startsWith("ws://") || src.startsWith("wss://");
  const playerSrc = isLive ? { driver: "websocket", url: src } : src;

  let extraOpts = {};
  if (el.dataset.playerOpts) {
    try {
      extraOpts = JSON.parse(el.dataset.playerOpts);
    } catch (e) {
      console.warn("admin player: invalid data-player-opts JSON", e);
    }
  }

  await createPlayer(playerSrc, el, { fit: "width", preload: !isLive, ...extraOpts });
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

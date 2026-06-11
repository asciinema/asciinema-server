import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { create as createPlayer } from "asciinema-player";

document.addEventListener("submit", (event) => {
  const message = event.target?.getAttribute?.("data-confirm");
  if (message && !window.confirm(message)) {
    event.preventDefault();
  }
});

function mountPlayer() {
  const el = document.getElementById("player");
  if (el && el.dataset.src && !el.dataset.mounted) {
    el.dataset.mounted = "1";
    createPlayer(el.dataset.src, el, { fit: "width" });
  }
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

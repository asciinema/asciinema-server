import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

document.addEventListener("submit", (event) => {
  const message = event.target?.getAttribute?.("data-confirm");
  if (message && !window.confirm(message)) {
    event.preventDefault();
  }
});

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();
window.liveSocket = liveSocket;

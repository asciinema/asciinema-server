import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { createPlayer } from "./player";

document.addEventListener("submit", (event) => {
  const form = event.target;

  const message = form?.getAttribute?.("data-confirm");
  if (message && !window.confirm(message)) {
    event.preventDefault();
    return;
  }

  const promptMessage = form?.getAttribute?.("data-prompt");
  if (promptMessage) {
    const field = form.querySelector("input[name='name']");
    const next = window.prompt(promptMessage, field?.value || "");
    if (next === null || next.trim() === "") {
      event.preventDefault();
      return;
    }
    field.value = next.trim();
  }
});

document.addEventListener("click", (event) => {
  const opener = event.target?.closest?.("[data-dialog-target]");
  if (!opener) return;

  const dialog = document.getElementById(opener.dataset.dialogTarget);
  if (dialog?.showModal) dialog.showModal();
});

// A backdrop click targets the dialog itself with coordinates outside its
// content box; clicks on the content bubble from inner elements.
document.addEventListener("click", (event) => {
  const dialog = event.target;
  if (!(dialog instanceof HTMLDialogElement) || !dialog.open) return;

  const rect = dialog.getBoundingClientRect();
  const outside =
    event.clientX < rect.left ||
    event.clientX > rect.right ||
    event.clientY < rect.top ||
    event.clientY > rect.bottom;

  if (outside) dialog.close();
});

// "/" focuses the index search box (GitHub-style).
document.addEventListener("keydown", (event) => {
  if (event.key !== "/" || event.ctrlKey || event.metaKey || event.altKey) return;

  const el = event.target;
  const tag = el?.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || el?.isContentEditable) return;
  if (document.querySelector("dialog[open]")) return;

  const search = document.querySelector("[data-query-autocomplete] input[name='q']");
  if (!search) return;

  event.preventDefault();
  search.focus();
  const end = search.value.length;
  search.setSelectionRange(end, end);
});

document.addEventListener("change", (event) => {
  const el = event.target;
  if (el?.matches?.("[data-autosubmit]") && el.form) el.form.requestSubmit();
});

function mountQueryAutocomplete() {
  document.querySelectorAll("[data-query-autocomplete]").forEach((wrap) => {
    const input = wrap.querySelector("input");
    if (!input || wrap.dataset.mounted) return;
    wrap.dataset.mounted = "1";

    let data = { tokens: [], values: {} };
    try {
      data = JSON.parse(wrap.dataset.suggestions || "{}");
    } catch (_e) {}

    const menu = document.createElement("div");
    menu.className = "query-suggestions hidden";
    wrap.appendChild(menu);

    // -1 = nothing selected, so Enter submits the typed text.
    let selected = -1;
    let items = [];

    const fragment = () => {
      const pos = input.selectionStart ?? input.value.length;
      const before = input.value.slice(0, pos);
      const start = before.search(/\S+$/);
      return {
        start: start === -1 ? pos : start,
        end: pos,
        text: start === -1 ? "" : before.slice(start),
      };
    };

    const completion = (text, item) =>
      text.includes(":") ? `${text.split(":", 1)[0]}:${item}` : `${item}:`;

    const render = () => {
      const frag = fragment();
      const [token, value] = frag.text.split(":", 2);

      if (frag.text.includes(":")) {
        items = data.values?.[token] || [];
        if (value) items = items.filter((item) => item.startsWith(value));
      } else {
        items = (data.tokens || []).filter((item) => item.startsWith(frag.text));
      }

      // drop already fully-typed suggestions so the popup closes once a value is complete
      items = items.slice(0, 8).filter((item) => completion(frag.text, item) !== frag.text);
      menu.innerHTML = "";

      if (items.length === 0 || frag.text === "") {
        menu.classList.add("hidden");
        return;
      }

      items.forEach((item, index) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = frag.text.includes(":") ? item : `${item}:`;
        button.className = index === selected ? "active" : "";
        button.addEventListener("mousedown", (event) => {
          event.preventDefault();
          accept(index);
        });
        menu.appendChild(button);
      });

      menu.classList.remove("hidden");
    };

    const accept = (index) => {
      const item = items[index];
      if (!item) return;

      const frag = fragment();
      const replacement = completion(frag.text, item);
      input.value = input.value.slice(0, frag.start) + replacement + input.value.slice(frag.end);
      input.setSelectionRange(frag.start + replacement.length, frag.start + replacement.length);
      input.focus();
      selected = -1;
      render();
    };

    const refresh = () => {
      selected = -1;
      render();
    };
    input.addEventListener("input", refresh);
    input.addEventListener("click", refresh);
    input.addEventListener("keydown", (event) => {
      if (menu.classList.contains("hidden")) return;

      if (event.key === "ArrowDown") {
        event.preventDefault();
        selected = Math.min(selected + 1, items.length - 1);
        render();
      } else if (event.key === "ArrowUp") {
        event.preventDefault();
        selected = Math.max(selected - 1, 0);
        render();
      } else if (event.key === "Tab") {
        event.preventDefault();
        accept(selected >= 0 ? selected : 0);
      } else if (event.key === "Enter") {
        // accept only an explicitly navigated suggestion; plain Enter submits the typed text
        if (selected >= 0) {
          event.preventDefault();
          accept(selected);
        }
      } else if (event.key === "Escape") {
        menu.classList.add("hidden");
      }
    });

    // suggestion clicks use mousedown + preventDefault, so blur fires only on a genuine click/tab away
    input.addEventListener("blur", () => menu.classList.add("hidden"));
  });
}

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

document.addEventListener("DOMContentLoaded", () => {
  mountPlayer();
  mountQueryAutocomplete();
});

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();
window.liveSocket = liveSocket;

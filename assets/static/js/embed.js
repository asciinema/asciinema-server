// asciinema embedded player

(function() {
  function insertAfter(referenceNode, newNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
  }

  function params(container, script) {
    if (script.dataset.t !== undefined) {
      script.dataset.startAt = script.dataset.t;
    }

    if (script.dataset.i !== undefined) {
      script.dataset.idleTimeLimit = script.dataset.i;
    }

    if (script.dataset.autoplay === '') {
      script.dataset.autoplay = '1';
    }

    if (script.dataset.loop === '') {
      script.dataset.loop = '1';
    }

    if (script.dataset.preload === '') {
      script.dataset.preload = '1';
    }

    const keys = new Set(['speed', 'autoplay', 'loop', 'theme', 'startAt', 'preload', 'cols', 'rows', 'idleTimeLimit', 'poster']);

    return Object.entries(script.dataset)
      .filter(([key, _]) => keys.has(key))
      .map(kv => kv.join('='))
      .join('&');
  }

  function locationFromString(string) {
    const parser = document.createElement('a');
    parser.href = string;
    return parser;
  }

  function apiHostFromScript(script) {
    const location = locationFromString(script.src);
    return location.protocol + '//' + location.host;
  }

  function insertPlayer(script) {
    if (script.dataset.initialized !== undefined) {
      return;
    }

    const apiHost = apiHostFromScript(script);
    const asciicastId = script.id.split('-')[1];
    const container = document.createElement('div');

    container.id = "asciicast-container-" + asciicastId;
    container.className = 'asciicast';
    container.style.display = 'block';
    container.style.float = 'none';
    container.style.overflow = 'hidden';
    container.style.padding = 0;
    container.style.margin = '1.5em 0';
    container.style.colorScheme = 'light dark';

    insertAfter(script, container);

    const iframe = document.createElement('iframe');
    iframe.src = apiHost + "/a/" + asciicastId + '/iframe?' + params(container, script);
    iframe.id = "asciicast-iframe-" + asciicastId;
    iframe.name = "asciicast-iframe-" + asciicastId;
    iframe.scrolling = "no";
    iframe.setAttribute('allowFullScreen', 'true');
    iframe.style.overflow = "hidden";
    iframe.style.margin = 0;
    iframe.style.border = 0;
    iframe.style.display = "inline-block";
    iframe.style.width = "100%";
    iframe.style.float = "none";
    iframe.style.visibility = "hidden";
    iframe.title = "Terminal session recording"

    function syncTextStyle() {
      const style = window.getComputedStyle(container);
      const color = style.getPropertyValue("color");
      const fontFamily = style.getPropertyValue("font-family");
      const fontSize = style.getPropertyValue("font-size");
      iframe.contentWindow.postMessage({ type: 'textStyle', payload: { color, fontFamily, fontSize } }, apiHost);
    }

    iframe.onload = function() {
      syncTextStyle();
      setTimeout(syncTextStyle, 1000);
      this.style.visibility = 'visible'

      if (window.matchMedia) {
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', syncTextStyle);
      }
    };

    container.appendChild(iframe);

    window.addEventListener("message", (e) => {
      if (e.origin !== apiHost || e.source !== iframe.contentWindow) return;

      if (e.data.type === 'bodySize') {
        iframe.style.height = '' + e.data.payload.height + 'px';
      }
    }, false);

    script.dataset.initialized = '1';
  }

  [].forEach.call(
    document.querySelectorAll("script[id^='asciicast-']"),
    insertPlayer
  );
})();

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

    const keys = new Set(['speed', 'autoplay', 'loop', 'theme', 'startAt', 'preload', 'cols', 'rows', 'idleTimeLimit']);

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
    container.style.margin = '20px 0';

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
    iframe.onload = function() { this.style.visibility = 'visible' };

    container.appendChild(iframe);

    function receiveSize(e) {
      const name = e.data[0];
      const data = e.data[1];

      if (e.origin === apiHost && e.source === iframe.contentWindow && name === 'resize') {
        iframe.style.height = '' + data.height + 'px';
      }
    }

    window.addEventListener("message", receiveSize, false);
    script.dataset.initialized = '1';
  }

  [].forEach.call(
    document.querySelectorAll("script[id^='asciicast-']"),
    insertPlayer
  );
})();

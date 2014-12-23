// asciinema embedded player

(function() {
  function insertAfter(referenceNode, newNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
  }

  function params(container, script) {
    var params = [];

    var size = script.getAttribute('data-size');
    if (size) {
      params = params.concat(['size=' + size]);
    }
    var speed = script.getAttribute('data-speed');
    if (speed) {
      params = params.concat(['speed=' + speed]);
    }
    var autoplay = script.getAttribute('data-autoplay');
    if (autoplay) {
      params = params.concat(['autoplay=' + autoplay]);
    }
    var loop = script.getAttribute('data-loop');
    if (loop) {
      params = params.concat(['loop=' + loop]);
    }
    var theme = script.getAttribute('data-theme');
    if (theme) {
      params = params.concat(['theme=' + theme]);
    }

    return '?' + params.join('&');
  }

  function locationFromString(string) {
    var parser = document.createElement('a');
    parser.href = string;
    return parser;
  }

  function apiHostFromScript(script) {
    var location = locationFromString(script.src);
    return location.protocol + '//' + location.host;
  }

  function insertPlayer(script) {
    // do not insert player if there's one already associated with this script
    if (script.dataset.player) {
      return;
    }

    var apiHost = apiHostFromScript(script);
    var apiUrl = apiHost + '/api';

    var asciicastId = script.id.split('-')[1];

    var container = document.createElement('div');
    container.id = "asciicast-container-" + asciicastId;
    container.className = 'asciicast';
    container.style.display = 'block';
    container.style.float = 'none';
    container.style.overflow = 'hidden';
    container.style.padding = 0;
    container.style.margin = '20px 0';

    insertAfter(script, container);

    var iframe = document.createElement('iframe');
    iframe.src = apiUrl + "/asciicasts/" + asciicastId + params(container, script);
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
      if (e.origin === apiHost) {
        var event = e.data[0];
        var data  = e.data[1];
        if (event == 'asciicast:size' && data.id == asciicastId) {
          iframe.style.width  = '' + data.width + 'px';
          iframe.style.height = '' + data.height + 'px';
        }
      }
    }

    window.addEventListener("message", receiveSize, false);

    script.dataset.player = container;
  }

  var scripts = document.querySelectorAll("script[id^='asciicast-']")
  for (var i = 0; i < scripts.length; i++) {
    insertPlayer(scripts[i]);
  }

})();

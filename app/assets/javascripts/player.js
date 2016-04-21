//= require asciinema-player

function tryCreatePlayer(parentNode, asciicast, options) {
  function createPlayer() {
    asciinema_player.core.CreatePlayer(
      parentNode,
      asciicast.url,
      {
        width: asciicast.width,
        height: asciicast.height,
        snapshot: asciicast.snapshot,
        speed: options.speed,
        autoPlay: options.autoPlay,
        loop: options.loop,
        preload: options.preload,
        startAt: options.startAt,
        fontSize: options.fontSize,
        theme: options.theme,
        title: options.title,
        author: options.author,
        authorURL: options.authorURL,
        authorImgURL: options.authorImgURL
      }
    );
  }

  function fetch() {
    $.get('/api/asciicasts/' + asciicast.id + '.json', function(data) {
      asciicast = data;
      checkReadiness();
    });
  }

  function checkReadiness() {
    if (asciicast.url) {
      $('.processing-info').remove();
      createPlayer();
    } else {
      $('.processing-info').show();
      setTimeout(fetch, 2000);
    }
  }

  checkReadiness();
}

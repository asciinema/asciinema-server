//= require asciinema-player

function tryCreatePlayer(parentNode, asciicast, options) {
  function createPlayer() {
    asciinema_player.core.CreatePlayer(
      parentNode,
      asciicast.width, asciicast.height,
      asciicast.stdout_frames_url,
      asciicast.duration,
      {
        snapshot: asciicast.snapshot,
        speed: options.speed,
        autoPlay: options.autoPlay,
        loop: options.loop,
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
    if (asciicast.stdout_frames_url) {
      $('.processing-info').remove();
      createPlayer();
    } else {
      $('.processing-info').show();
      setTimeout(fetch, 2000);
    }
  }

  checkReadiness();
}

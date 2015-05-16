function createPlayer(parentNode, asciicast, options) {
  asciinema.CreatePlayer(
    parentNode,
    asciicast.width, asciicast.height,
    asciicast.stdout_frames_url,
    asciicast.duration,
    {
      snapshot: asciicast.snapshot,
      speed: options.speed,
      autoPlay: options.autoPlay,
      loop: options.loop,
      fontSize: options.fontSize,
      theme: options.theme
    }
  );
}

function tryCreatePlayer(parentNode, asciicast, options) {
  if (asciicast.stdout_frames_url) {
    $('.processing-info').remove();
    createPlayer(parentNode, asciicast, options);
  } else {
    $('.processing-info').show();
    setTimeout(function() {
      $.get('/api/asciicasts/' + asciicast.id + '.json', function(data) {
        tryCreatePlayer(parentNode, data, options);
      });
    }, 2000);
  }
}

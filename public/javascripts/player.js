var SP = {};

var speed = 1.0;
var minDelay = 0.01;

SP.Player = function(cols, lines, data, time) {
  this.terminal = new SP.Terminal(cols, lines);
  this.interpreter = new SP.AnsiInterpreter(this.terminal);
  this.data = data;
  this.time = time;
  this.dataIndex = 0;
  this.frame = 0;
  this.currentData = "";
  console.log("started");
  this.nextFrame();
};

SP.Player.prototype = {
  nextFrame: function() {
    var timing = this.time[this.frame];

    if (!timing) {
      console.log("finished");
      return;
    }

    this.terminal.restartCursorBlink();

    var run = function() {
      var rest = this.interpreter.feed(this.currentData);
      this.terminal.updateDirtyLines();
      var n = timing[1];

      if (rest.length > 0)
        console.log('rest: ' + rest);

      this.currentData = rest + this.data.slice(this.dataIndex, this.dataIndex + n);
      this.dataIndex += n;
      this.frame += 1;

      if (rest.length > 20) {
        var s = rest.slice(0, 10);
        var hex = '';
        for (i=0; i<s.length; i++) {
          hex += '0x' + s[i].charCodeAt(0).toString(16) + ',';
        }
        console.log("failed matching: '" + s + "' (" + hex + ")");
        return;
      }

      if (!window.stopped) {
        this.nextFrame();
      }
    }.bind(this);


    if (timing[0] > minDelay) {
      setTimeout(run, timing[0] * 1000 * (1.0 / speed));
    } else {
      run();
    }
  }
}

$(function() {
  $(window).bind('keyup', function(event) {
      if (event.keyCode == 27) {
        window.stopped = true;
      }
  });
});

$(function() { new SP.Player(cols, lines, data, time) });

var SP = {};

var speed = 1.0;

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

    // setTimeout(function() {
      // console.log(this.dataIndex);
      // console.log(this.currentData);
      this.interpreter.feed(this.currentData);
      this.terminal.updateDirtyLines();
      var n = timing[1];
      console.log(timing[0]);
      console.log(n);
      this.currentData = this.data.slice(this.dataIndex, this.dataIndex + n);
      this.dataIndex += n;
      this.frame += 1;
      if (!window.stopped) {
        this.nextFrame();
      }
    // }.bind(this), timing[0] * 1000 * (1.0 / speed));
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

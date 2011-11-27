SP.Terminal = function(cols, lines) {
  this.cols = cols;
  this.lines = lines;

  this.cursorX = 0;
  this.cursorY = 0;

  this.normalBuffer = [];
  this.alternateBuffer = [];
  this.lineData = this.normalBuffer;
  this.fg = this.bg = undefined;
  this.dirtyLines = [];
  this.initialize();
};

SP.Terminal.prototype = {
  initialize: function() {
    var container = $(".player .term");
    this.element = container;
    this.renderLine(0); // we only need 1 line
    this.element.css({ width: this.element.width(), height: this.element.height() * this.lines });
  },

  getLine: function(n) {
    n = (typeof n != "undefined" ? n : this.cursorY);

    var line = this.lineData[n];

    if (typeof line == 'undefined') {
      line = this.lineData[n] = [];
      this.fill(n, 0, this.cols, ' ');
    }

    return line;
  },

  clearScreen: function() {
    // this.lineData.length = 0;
    this.cursorY = this.cursorX = 0;
    this.element.find(".line").empty();
  },

  switchToNormalBuffer: function() {
    this.lineData = this.normalBuffer;
    this.updateScreen();
  },

  switchToAlternateBuffer: function() {
    this.lineData = this.alternateBuffer;
    this.updateScreen();
  },

  renderLine: function(n) {
    var html = this.getLine(n);

    if (n == this.cursorY) {
      html = html.slice(0, this.cursorX).concat(['<span class="cursor">' + (html[this.cursorX] || '') + "</span>"], html.slice(this.cursorX + 1) || []);
    }

    this.element.find(".line:eq(" + n + ")").html(html.join(''));
  },

  render: function() {
    var updated = [];

    for (var i=0; i<this.dirtyLines.length; i++) {
      var n = this.dirtyLines[i];
      if (updated.indexOf(n) == -1) {
        this.renderLine(n);
        updated.push(n);
      }
    }

    this.dirtyLines = [];
  },

  updateLine: function(n) {
    n = (typeof n != "undefined" ? n : this.cursorY);
    this.dirtyLines.push(n);
  },

  updateScreen: function() {
    this.dirtyLines = [];

    for (var l=0; l<this.lineData.length; l++) {
      this.dirtyLines.push(l);
    }
  },

  showCursor: function(show) {
    if (show) {
      this.element.addClass('cursor-on');
    } else {
      this.element.removeClass('cursor-on');
    }
  },

  setSGR: function(codes) {
    if (codes.length == 0) {
      codes = [0];
    }

    for (var i=0; i<codes.length; i++) {
      var n = codes[i];

      if (n === 0) {
        this.fg = this.bg = undefined;
        this.bright = false;
      } else if (n == 1) {
        this.bright = true;
      } else if (n >= 30 && n <= 37) {
        this.fg = n - 30;
      } else if (n >= 40 && n <= 47) {
        this.bg = n - 40;
      } else if (n == 38) {
        this.fg = codes[i+2];
        i += 2;
      } else if (n == 48) {
        this.bg = codes[i+2];
        i += 2;
      }
    }
  },

  setCursorPos: function(line, col) {
    line -= 1;
    col -= 1;
    var oldLine = this.cursorY;
    this.cursorY = line;
    this.cursorX = col;
    this.updateLine(oldLine);
    this.updateLine();
  },

  saveCursor: function() {
    this.savedCol = this.cursorX;
    this.savedLine = this.cursorY;
  },

  restoreCursor: function() {
    var oldLine = this.cursorY;

    this.cursorY = this.savedLine;
    this.cursorX = this.savedCol;

    this.updateLine(oldLine);
    this.updateLine();
  },

  cursorLeft: function() {
    if (this.cursorX > 0) {
      this.cursorX -= 1;
      this.updateLine();
    }
  },

  cursorRight: function() {
    if (this.cursorX < this.cols) {
      this.cursorX += 1;
      this.updateLine();
    }
  },

  cursorUp: function() {
    if (this.cursorY > 0) {
      this.cursorY -= 1;
      this.updateLine(this.cursorY);
      this.updateLine(this.cursorY+1);
    }
  },

  cursorDown: function() {
    if (this.cursorY + 1 < this.lines) {
      this.cursorY += 1;
      this.updateLine(this.cursorY-1);
      this.updateLine(this.cursorY);
    } else {
      this.lineData.splice(0, 1);
      this.updateScreen();
    }
  },

  cursorForward: function(n) {
    for (var i=0; i<n; i++) this.cursorRight();
  },

  cursorBack: function(n) {
    for (var i=0; i<n; i++) this.cursorLeft();
  },

  cr: function() {
    this.cursorX = 0;
    this.updateLine();
  },

  bs: function() {
    if (this.cursorX > 0) {
      this.getLine()[this.cursorX - 1] = ' ';
      this.cursorX -= 1;
      this.updateLine();
    }
  },

  print: function(text) {
    text = Utf8.decode(text);

    for (var i=0; i<text.length; i++) {
      if (this.cursorX >= this.cols) {
        this.cursorY += 1;
        this.cursorX = 0;
      }

      this.fill(this.cursorY, this.cursorX, 1, text[i]);
      this.cursorX += 1;
    }

    this.updateLine();
  },

  eraseData: function(n) {
    if (n == 0) {
      this.eraseLine(0);
      for (var l=this.cursorY+1; l<this.lines; l++) {
        this.clearLineData(l);
        this.updateLine(l);
      }
    } else if (n == 1) {
      for (var l=0; l<this.cursorY; l++) {
        this.clearLineData(l);
        this.updateLine(l);
      }
      this.eraseLine(n);
    } else if (n == 2) {
      for (var l=0; l<this.lines; l++) {
        this.clearLineData(l);
        this.updateLine(l);
      }
    }
  },

  eraseLine: function(n) {
    if (n == 0) {
      this.fill(this.cursorY, this.cursorX, this.cols - this.cursorX, ' ');
      this.updateLine();
    } else if (n == 1) {
      this.fill(this.cursorY, 0, this.cursorX, ' ');
      this.updateLine();
    } else if (n == 2) {
      this.fill(this.cursorY, 0, this.cols, ' ');
      this.updateLine();
    }
  },

  clearLineData: function(n) {
    this.fill(n, 0, this.cols, ' ');
  },

  reserveCharacters: function(n) {
    var line = this.getLine();
    this.lineData[this.cursorY] = line.slice(0, this.cursorX).concat(" ".times(n).split(''), line.slice(this.cursorX, this.cols - n));
    this.updateLine();
  },

  ri: function(n) {
    for (var i=0; i<n; i++) {
      if (this.cursorY == 0) {
        this.insertLines(0, n);
      } else {
        this.cursorUp();
      }
    }
  },

  insertLines: function(l, n) {
    for (var i=0; i<n; i++) {
      this.lineData.splice(l, 0, []);
      this.clearLineData(l);
    }

    this.lineData.length = this.lines;

    this.updateScreen();
  },

  fill: function(line, col, n, char) {
    var prefix = '', postfix = '';

    if (this.fg !== undefined || this.bg !== undefined || this.bright) {
      prefix = '<span class="';
      var brightOffset = this.bright ? 8 : 0;

      if (this.fg !== undefined) {
        prefix += ' fg' + (this.fg + brightOffset);
      } else if (this.bright) {
        prefix += ' bright';
      }

      if (this.bg !== undefined) {
        prefix += ' bg' + this.bg;
      }

      prefix += '">';
      postfix = '</span>';
    }

    var char = prefix + char + postfix;

    var lineArr = this.getLine(line);

    for (var i=0; i<n; i++) {
      lineArr[col+i] = char;
    }
  },

  blinkCursor: function() {
    var cursor = this.element.find(".cursor");
    if (cursor.hasClass("inverted")) {
      cursor.removeClass("inverted");
    } else {
      cursor.addClass("inverted");
    }
  },

  restartCursorBlink: function() {
    if (this.cursorTimerId) {
      clearInterval(this.cursorTimerId);
      this.cursorTimerId = null;
    }
    this.cursorTimerId = setInterval(this.blinkCursor.bind(this), 500);
  }
};

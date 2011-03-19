SP.Terminal = function(cols, lines) {
  this.cols = cols;
  this.lines = lines;
  this.cursorLine = 0;
  this.cursorCol = 0;
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
    this.element.css({ height: this.element.height() * this.lines });
  },

  getLine: function(n) {
    n = (typeof n != "undefined" ? n : this.cursorLine);

    var line = this.lineData[n];

    if (typeof line == 'undefined') {
      line = this.lineData[n] = [];
      this.fill(n, 0, this.cols, ' ');
    }

    return line;
  },

  clearScreen: function() {
    this.lineData.length = 0;
    this.cursorLine = this.cursorCol = 0;
    this.element.empty();
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

    if (n == this.cursorLine) {
      html = html.slice(0, this.cursorCol).concat(['<span class="cursor">' + (html[this.cursorCol] || '') + "</span>"], html.slice(this.cursorCol + 1) || []);
    }

    var missingLines = this.lineData.length - this.element.find('.line').length;

    for (var i = 0; i < missingLines; i++) {
      var row = $('<span class="line">');
      this.element.append(row);
      this.element.append("\n");
      this.element.scrollTop(100000);//row.offset().top);
    }

    this.element.find(".line:eq(" + n + ")").html(html.join(''));
  },

  renderDirtyLines: function() {
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
    n = (typeof n != "undefined" ? n : this.cursorLine);
    this.dirtyLines.push(n);
  },

  updateScreen: function() {
    this.dirtyLines = [];

    for (var l=0; l<this.lineData.length; l++) {
      this.dirtyLines.push(l);
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
    var oldLine = this.cursorLine;
    this.cursorLine = line;
    this.cursorCol = col;
    this.updateLine(oldLine);
    this.updateLine();
  },

  saveCursor: function() {
    this.savedCol = this.cursorCol;
    this.savedLine = this.cursorLine;
  },

  restoreCursor: function() {
    var oldLine = this.cursorLine;

    this.cursorLine = this.savedLine;
    this.cursorCol = this.savedCol;

    this.updateLine(oldLine);
    this.updateLine();
  },

  cursorLeft: function() {
    if (this.cursorCol > 0) {
      this.cursorCol -= 1;
      this.updateLine();
    }
  },

  cursorRight: function() {
    if (this.cursorCol < this.cols) {
      this.cursorCol += 1;
      this.updateLine();
    }
  },

  cursorUp: function() {
    if (this.cursorLine > 0) {
      this.cursorLine -= 1;
      this.updateLine(this.cursorLine);
      this.updateLine(this.cursorLine+1);
    }
  },

  cursorDown: function() {
    this.cursorLine += 1;
    this.updateLine(this.cursorLine);
    this.updateLine(this.cursorLine-1);
  },

  cursorForward: function(n) {
    for (var i=0; i<n; i++) this.cursorRight();
  },

  cursorBack: function(n) {
    for (var i=0; i<n; i++) this.cursorLeft();
  },

  cr: function() {
    this.cursorCol = 0;
    this.updateLine();
  },

  bs: function() {
    if (this.cursorCol > 0) {
      this.getLine()[this.cursorCol - 1] = ' ';
      this.cursorCol -= 1;
      this.updateLine();
    }
  },

  print: function(text) {
    text = Utf8.decode(text);

    for (var i=0; i<text.length; i++) {
      if (this.cursorCol >= this.cols) {
        this.cursorLine += 1;
        this.cursorCol = 0;
      }

      this.fill(this.cursorLine, this.cursorCol, 1, text[i]);
      this.cursorCol += 1;
    }

    this.updateLine();
  },

  eraseData: function(n) {
    if (n == 0) {
      this.eraseLine(0);
      for (var l=this.cursorLine+1; l<this.lineData.length; l++) {
        this.lineData[l] = [];
        this.updateLine(l);
      }
    } else if (n == 1) {
      for (var l=0; l<this.cursorLine; l++) {
        this.lineData[l] = [];
        this.updateLine(l);
      }
      this.eraseLine(n);
    } else if (n == 2) {
      for (var l=0; l<this.lineData.length; l++) {
        this.lineData[l] = [];
        this.updateLine(l);
      }
    }
  },

  eraseLine: function(n) {
    if (n == 0) {
      this.fill(this.cursorLine, this.cursorCol, this.cols - this.cursorCol, ' ');
      // this.lineData[this.cursorLine] = this.lineData[this.cursorLine].slice(0, this.cursorCol);
      // this.lineData[this.cursorLine] = this.lineData[this.cursorLine].slice(0, this.cursorCol) + " ".times(this.cols - this.cursorCol);
      this.updateLine();
    } else if (n == 1) {
      this.fill(this.cursorLine, 0, this.cursorCol, ' ');
      // this.lineData[this.cursorLine] = " ".times(this.cursorCol).split('').concat(this.lineData[this.cursorLine].slice(this.cursorCol));
      // this.lineData[this.cursorLine] = " ".times(this.cursorCol) + this.lineData[this.cursorLine].slice(this.cursorCol);
      this.updateLine();
    } else if (n == 2) {
      this.fill(this.cursorLine, 0, this.cols, ' ');
      // this.lineData[this.cursorLine] = [] // " ".times(this.cols);
      this.updateLine();
    }
  },

  reserveCharacters: function(n) {
    var line = this.getLine();
    this.lineData[this.cursorLine] = line.slice(0, this.cursorCol).concat(" ".times(n).split(''), line.slice(this.cursorCol, this.cols - n));
    this.updateLine();
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

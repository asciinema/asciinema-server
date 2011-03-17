SP.Terminal = function(cols, lines) {
  this.cols = cols;
  this.lines = lines;
  this.cursorLine = 0;
  this.cursorCol = 0;
  this.lineData = [];
  this.fg = this.bg = undefined;
  this.dirtyLines = [];
  this.initialize();
};

SP.Terminal.prototype = {
  initialize: function() {
    var container = $(".player .term");
    this.element = container;
    for (l = 0; l < this.lines; l++) {
      var row = $("<span class='line'>");
      container.append(row);
      container.append("\n");
      this.lineData[l] = [];
      this.updateLine(l);
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
      }
    }
  },

  updateLine: function(n) {
    n = (typeof n != "undefined" ? n : this.cursorLine);
    this.dirtyLines.push(n);
  },

  updateDirtyLines: function() {
    var updated = [];

    for (var i=0; i<this.dirtyLines.length; i++) {
      var n = this.dirtyLines[i];
      if (updated.indexOf(n) == -1) {
        this._updateLine(n);
        updated.push(n);
      }
    }

    this.dirtyLines = [];
  },

  _updateLine: function(n) {
    var html;

    if (n == this.cursorLine) {
      var text = this.lineData[n];
      html = text.slice(0, this.cursorCol).concat(['<span class="cursor">' + (text[this.cursorCol] || '') + "</span>"], text.slice(this.cursorCol + 1) || []);
    } else {
      html = this.lineData[n];
    }

    this.element.find(".line:eq(" + n + ")").html(html.join(''));
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
    if (this.cursorCol > 0)
      this.cursorCol = this.cursorCol - 1;
    this.updateLine();
  },

  cursorRight: function() {
    if (this.cursorCol < this.cols)
      this.cursorCol = this.cursorCol + 1;
    this.updateLine();
  },

  cursorUp: function() {
    if (this.cursorLine > 0)
      this.cursorLine = this.cursorLine - 1;
    this.updateLine(this.cursorLine);
    this.updateLine(this.cursorLine+1);
  },

  cursorDown: function() {
    if (this.cursorLine < this.lines)
      this.cursorLine = this.cursorLine + 1;
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
      this.lineData[this.cursorLine][this.cursorCol - 1] = ' ';
      this.cursorCol = this.cursorCol - 1;
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
      this.cursorCol = this.cursorCol + 1;
    }

    this.updateLine();
  },

  eraseData: function(n) {
    if (n == 0) {
      this.eraseLine(n);
      for (var l=this.cursorLine+1; l<this.lines; l++) {
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
      for (var l=0; l<this.lines; l++) {
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
      this.updateLine(this.cursorLine);
    } else if (n == 1) {
      this.fill(this.cursorLine, 0, this.cursorCol, ' ');
      // this.lineData[this.cursorLine] = " ".times(this.cursorCol).split('').concat(this.lineData[this.cursorLine].slice(this.cursorCol));
      // this.lineData[this.cursorLine] = " ".times(this.cursorCol) + this.lineData[this.cursorLine].slice(this.cursorCol);
      this.updateLine(this.cursorLine);
    } else if (n == 2) {
      this.fill(this.cursorLine, 0, this.cols, ' ');
      // this.lineData[this.cursorLine] = [] // " ".times(this.cols);
      this.updateLine(this.cursorLine);
    }
  },

  reserveCharacters: function(n) {
    var line = this.lineData[this.cursorLine];
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

    for (var i=0; i<n; i++) {
      this.lineData[line][col+i] = char;
    }
    // this.lineData[line] = this.lineData[line].slice(0, col).concat(char, this.lineData[line].slice(col + 1));
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

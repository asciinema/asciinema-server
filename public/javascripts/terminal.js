/* var CP437_DICT = {
 '\x01' : ["&#x263A;", "WHITE SMILING FACE"],
 '\x02' : ["&#x263B;", "BLACK SMILING FACE"],
 '\x03' : ["&#x2665;", "BLACK HEART SUIT"],
 '\x04' : ["&#x2666;", "BLACK DIAMOND SUIT"],
 '\x05' : ["&#x2663;", "BLACK CLUB SUIT"],
 '\x06' : ["&#x2660;", "BLACK SPADE SUIT"],
 '\x07' : ["&#x2022;", "BULLET"],
 '\x08' : ["&#x25D8;", "INVERSE BULLET"],
 '\x09' : ["&#x25CB;", "WHITE CIRCLE"],
 '\x0a' : ["&#x25D9;", "INVERSE WHITE CIRCLE"],
 '\x0b' : ["&#x2642;", "MALE SIGN"],
 '\x0c' : ["&#x2640;", "FEMALE SIGN"],
 '\x0d' : ["&#x266A;", "EIGHTH NOTE"],
 '\x0e' : ["&#x266B;", "BEAMED EIGHTH NOTES"],
 '\x0f' : ["&#x263C;", "WHITE SUN WITH RAYS"],
 '\x10' : ["&#x25B8;", "BLACK RIGHT-POINTING SMALL TRIANGLE"],
 '\x11' : ["&#x25C2;", "BLACK LEFT-POINTING SMALL TRIANGLE"],
 '\x12' : ["&#x2195;", "UP DOWN ARROW"],
 '\x13' : ["&#x203C;", "DOUBLE EXCLAMATION MARK"],
 '\x14' : ["&#x00B6;", "PILCROW SIGN"],
 '\x15' : ["&#x00A7;", "SECTION SIGN"],
 '\x16' : ["&#x25AC;", "BLACK RECTANGLE"],
 '\x17' : ["&#x21A8;", "UP DOWN ARROW WITH BASE"],
 '\x18' : ["&#x2191;", "UPWARDS ARROW"],
 '\x19' : ["&#x2193;", "DOWNWARDS ARROW"],
 '\x1a' : ["&#x2192;", "RIGHTWARDS ARROW"],
 '\x1b' : ["&#x2190;", "LEFTWARDS ARROW"],
 '\x1c' : ["&#x221F;", "RIGHT ANGLE"],
 '\x1d' : ["&#x2194;", "LEFT RIGHT ARROW"],
 '\x1e' : ["&#x25B4;", "BLACK UP-POINTING SMALL TRIANGLE"],
 '\x1f' : ["&#x25BE;", "BLACK DOWN-POINTING SMALL TRIANGLE"],
 '\x21' : ["&#x0021;", "EXCLAMATION MARK"],
 '\x22' : ["&#x0022;", "QUOTATION MARK"],
 '\x23' : ["&#x0023;", "NUMBER SIGN"],
 '\x24' : ["&#x0024;", "DOLLAR SIGN"],
 '\x25' : ["&#x0025;", "PERCENT SIGN"],
 '\x26' : ["&#x0026;", "AMPERSAND"],
 '\x27' : ["&#x0027;", "APOSTROPHE"],
 '\x28' : ["&#x0028;", "LEFT PARENTHESIS"],
 '\x29' : ["&#x0029;", "RIGHT PARENTHESIS"],
 '\x2a' : ["&#x002A;", "ASTERISK"],
 '\x2b' : ["&#x002B;", "PLUS SIGN"],
 '\x2c' : ["&#x002C;", "COMMA"],
 '\x2d' : ["&#x002D;", "HYPHEN-MINUS"],
 '\x2e' : ["&#x002E;", "FULL STOP"],
 '\x2f' : ["&#x002F;", "SOLIDUS"],
 '\x7f' : ["&#x2302;", "HOUSE"],
 '\x80' : ["&#x00C7;", "LATIN CAPITAL LETTER C WITH CEDILLA"],
 '\x81' : ["&#x00FC;", "LATIN SMALL LETTER U WITH DIAERESIS"],
 '\x82' : ["&#x00E9;", "LATIN SMALL LETTER E WITH ACUTE"],
 '\x83' : ["&#x00E2;", "LATIN SMALL LETTER A WITH CIRCUMFLEX"],
 '\x84' : ["&#x00E4;", "LATIN SMALL LETTER A WITH DIAERESIS"],
 '\x85' : ["&#x00E0;", "LATIN SMALL LETTER A WITH GRAVE"],
 '\x86' : ["&#x00E5;", "LATIN SMALL LETTER A WITH RING ABOVE"],
 '\x87' : ["&#x00E7;", "LATIN SMALL LETTER C WITH CEDILLA"],
 '\x88' : ["&#x00EA;", "LATIN SMALL LETTER E WITH CIRCUMFLEX"],
 '\x89' : ["&#x00EB;", "LATIN SMALL LETTER E WITH DIAERESIS"],
 '\x8a' : ["&#x00E8;", "LATIN SMALL LETTER E WITH GRAVE"],
 '\x8b' : ["&#x00EF;", "LATIN SMALL LETTER I WITH DIAERESIS"],
 '\x8c' : ["&#x00EE;", "LATIN SMALL LETTER I WITH CIRCUMFLEX"],
 '\x8d' : ["&#x00EC;", "LATIN SMALL LETTER I WITH GRAVE"],
 '\x8e' : ["&#x00C4;", "LATIN CAPITAL LETTER A WITH DIAERESIS"],
 '\x8f' : ["&#x00C5;", "LATIN CAPITAL LETTER A WITH RING ABOVE"],
 '\x90' : ["&#x00C9;", "LATIN CAPITAL LETTER E WITH ACUTE"],
 '\x91' : ["&#x00E6;", "LATIN SMALL LETTER AE"],
 '\x92' : ["&#x00C6;", "LATIN CAPITAL LETTER AE"],
 '\x93' : ["&#x00F4;", "LATIN SMALL LETTER O WITH CIRCUMFLEX"],
 '\x94' : ["&#x00F6;", "LATIN SMALL LETTER O WITH DIAERESIS"],
 '\x95' : ["&#x00F2;", "LATIN SMALL LETTER O WITH GRAVE"],
 '\x96' : ["&#x00FB;", "LATIN SMALL LETTER U WITH CIRCUMFLEX"],
 '\x97' : ["&#x00F9;", "LATIN SMALL LETTER U WITH GRAVE"],
 '\x98' : ["&#x00FF;", "LATIN SMALL LETTER Y WITH DIAERESIS"],
 '\x99' : ["&#x00D6;", "LATIN CAPITAL LETTER O WITH DIAERESIS"],
 '\x9a' : ["&#x00DC;", "LATIN CAPITAL LETTER U WITH DIAERESIS"],
 '\x9b' : ["&#x00A2;", "CENT SIGN"],
 '\x9c' : ["&#x00A3;", "POUND SIGN"],
 '\x9d' : ["&#x00A5;", "YEN SIGN"],
 '\x9e' : ["&#x20A7;", "PESETA SIGN"],
 '\x9f' : ["&#x0192;", "LATIN SMALL LETTER F WITH HOOK"],
 '\xa0' : ["&#x00E1;", "LATIN SMALL LETTER A WITH ACUTE"],
 '\xa1' : ["&#x00ED;", "LATIN SMALL LETTER I WITH ACUTE"],
 '\xa2' : ["&#x00F3;", "LATIN SMALL LETTER O WITH ACUTE"],
 '\xa3' : ["&#x00FA;", "LATIN SMALL LETTER U WITH ACUTE"],
 '\xa4' : ["&#x00F1;", "LATIN SMALL LETTER N WITH TILDE"],
 '\xa5' : ["&#x00D1;", "LATIN CAPITAL LETTER N WITH TILDE"],
 '\xa6' : ["&#x00AA;", "FEMININE ORDINAL INDICATOR"],
 '\xa7' : ["&#x00BA;", "MASCULINE ORDINAL INDICATOR"],
 '\xa8' : ["&#x00BF;", "INVERTED QUESTION MARK"],
 '\xa9' : ["&#x2310;", "REVERSED NOT SIGN"],
 '\xaa' : ["&#x00AC;", "NOT SIGN"],
 '\xab' : ["&#x00BD;", "VULGAR FRACTION ONE HALF"],
 '\xac' : ["&#x00BC;", "VULGAR FRACTION ONE QUARTER"],
 '\xad' : ["&#x00A1;", "INVERTED EXCLAMATION MARK"],
 '\xae' : ["&#x00AB;", "LEFT-POINTING DOUBLE ANGLE QUOTATION MARK"],
 '\xaf' : ["&#x00BB;", "RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK"],
 '\xb0' : ["&#x2591;", "LIGHT SHADE"],
 '\xb1' : ["&#x2592;", "MEDIUM SHADE"],
 '\xb2' : ["&#x2593;", "DARK SHADE"],
 '\xb3' : ["&#x2502;", "BOX DRAWINGS LIGHT VERTICAL"],
 '\xb4' : ["&#x2524;", "BOX DRAWINGS LIGHT VERTICAL AND LEFT"],
 '\xb5' : ["&#x2561;", "BOX DRAWINGS VERTICAL SINGLE AND LEFT DOUBLE"],
 '\xb6' : ["&#x2562;", "BOX DRAWINGS VERTICAL DOUBLE AND LEFT SINGLE"],
 '\xb7' : ["&#x2556;", "BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE"],
 '\xb8' : ["&#x2555;", "BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE"],
 '\xb9' : ["&#x2563;", "BOX DRAWINGS DOUBLE VERTICAL AND LEFT"],
 '\xba' : ["&#x2551;", "BOX DRAWINGS DOUBLE VERTICAL"],
 '\xbb' : ["&#x2557;", "BOX DRAWINGS DOUBLE DOWN AND LEFT"],
 '\xbc' : ["&#x255D;", "BOX DRAWINGS DOUBLE UP AND LEFT"],
 '\xbd' : ["&#x255C;", "BOX DRAWINGS UP DOUBLE AND LEFT SINGLE"],
 '\xbe' : ["&#x255B;", "BOX DRAWINGS UP SINGLE AND LEFT DOUBLE"],
 '\xbf' : ["&#x2510;", "BOX DRAWINGS LIGHT DOWN AND LEFT"],
 '\xc0' : ["&#x2514;", "BOX DRAWINGS LIGHT UP AND RIGHT"],
 '\xc1' : ["&#x2534;", "BOX DRAWINGS LIGHT UP AND HORIZONTAL"],
 '\xc2' : ["&#x252C;", "BOX DRAWINGS LIGHT DOWN AND HORIZONTAL"],
 '\xc3' : ["&#x251C;", "BOX DRAWINGS LIGHT VERTICAL AND RIGHT"],
 '\xc4' : ["&#x2500;", "BOX DRAWINGS LIGHT HORIZONTAL"],
 '\xc5' : ["&#x253C;", "BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL"],
 '\xc6' : ["&#x255E;", "BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE"],
 '\xc7' : ["&#x255F;", "BOX DRAWINGS VERTICAL DOUBLE AND RIGHT SINGLE"],
 '\xc8' : ["&#x255A;", "BOX DRAWINGS DOUBLE UP AND RIGHT"],
 '\xc9' : ["&#x2554;", "BOX DRAWINGS DOUBLE DOWN AND RIGHT"],
 '\xca' : ["&#x2569;", "BOX DRAWINGS DOUBLE UP AND HORIZONTAL"],
 '\xcb' : ["&#x2566;", "BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL"],
 '\xcc' : ["&#x2560;", "BOX DRAWINGS DOUBLE VERTICAL AND RIGHT"],
 '\xcd' : ["&#x2550;", "BOX DRAWINGS DOUBLE HORIZONTAL"],
 '\xce' : ["&#x256C;", "BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL"],
 '\xcf' : ["&#x2567;", "BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE"],
 '\xd0' : ["&#x2568;", "BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE"],
 '\xd1' : ["&#x2564;", "BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE"],
 '\xd2' : ["&#x2565;", "BOX DRAWINGS DOWN DOUBLE AND HORIZONTAL SINGLE"],
 '\xd3' : ["&#x2559;", "BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE"],
 '\xd4' : ["&#x2558;", "BOX DRAWINGS UP SINGLE AND RIGHT DOUBLE"],
 '\xd5' : ["&#x2552;", "BOX DRAWINGS DOWN SINGLE AND RIGHT DOUBLE"],
 '\xd6' : ["&#x2553;", "BOX DRAWINGS DOWN DOUBLE AND RIGHT SINGLE"],
 '\xd7' : ["&#x256B;", "BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE"],
 '\xd8' : ["&#x256A;", "BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE"],
 '\xd9' : ["&#x2518;", "BOX DRAWINGS LIGHT UP AND LEFT"],
 '\xda' : ["&#x250C;", "BOX DRAWINGS LIGHT DOWN AND RIGHT"],
 '\xdb' : ["&#x2588;", "FULL BLOCK"],
 '\xdc' : ["&#x2584;", "LOWER HALF BLOCK"],
 '\xdd' : ["&#x258C;", "LEFT HALF BLOCK"],
 '\xde' : ["&#x2590;", "RIGHT HALF BLOCK"],
 '\xdf' : ["&#x2580;", "UPPER HALF BLOCK"],
 '\xe0' : ["&#x03B1;", "GREEK SMALL LETTER ALPHA"],
 '\xe1' : ["&#x03B2;", "GREEK SMALL LETTER BETA"],
 '\xe2' : ["&#x0393;", "GREEK CAPITAL LETTER GAMMA"],
 '\xe3' : ["&#x03C0;", "GREEK SMALL LETTER PI"],
 '\xe4' : ["&#x03A3;", "GREEK CAPITAL LETTER SIGMA"],
 '\xe5' : ["&#x03C3;", "GREEK SMALL LETTER SIGMA"],
 '\xe6' : ["&#x00B5;", "MICRO SIGN"],
 '\xe7' : ["&#x03C4;", "GREEK SMALL LETTER TAU"],
 '\xe8' : ["&#x03A6;", "GREEK CAPITAL LETTER PHI"],
 '\xe9' : ["&#x0398;", "GREEK CAPITAL LETTER THETA"],
 '\xea' : ["&#x03A9;", "GREEK CAPITAL LETTER OMEGA"],
 '\xeb' : ["&#x03B4;", "GREEK SMALL LETTER DELTA"],
 '\xec' : ["&#x221E;", "INFINITY"],
 '\xed' : ["&#x2205;", "EMPTY SET"],
 '\xee' : ["&#x2208;", "ELEMENT OF"],
 '\xef' : ["&#x2229;", "INTERSECTION"],
 '\xf0' : ["&#x2261;", "IDENTICAL TO"],
 '\xf1' : ["&#x00B1;", "PLUS-MINUS SIGN"],
 '\xf2' : ["&#x2265;", "GREATER-THAN OR EQUAL TO"],
 '\xf3' : ["&#x2264;", "LESS-THAN OR EQUAL TO"],
 '\xf4' : ["&#x2320;", "TOP HALF INTEGRAL"],
 '\xf5' : ["&#x2321;", "BOTTOM HALF INTEGRAL"],
 '\xf6' : ["&#x00F7;", "DIVISION SIGN"],
 '\xf7' : ["&#x2248;", "ALMOST EQUAL TO"],
 '\xf8' : ["&#x00B0;", "DEGREE SIGN"],
 '\xf9' : ["&#x2219;", "BULLET OPERATOR"],
 '\xfa' : ["&#x00B7;", "MIDDLE DOT"],
 '\xfb' : ["&#x221A;", "SQUARE ROOT"],
 '\xfc' : ["&#x207F;", "SUPERSCRIPT LATIN SMALL LETTER N"],
 '\xfd' : ["&#x00B2;", "SUPERSCRIPT TWO"],
 '\xfe' : ["&#x25AA;", "SMALL BLACK SQUARE"]
}
*/

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

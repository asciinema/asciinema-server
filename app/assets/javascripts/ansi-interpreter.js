SP.AnsiInterpreter = function(terminal) {
  this.terminal = terminal;
  this.compilePatterns();
}

SP.AnsiInterpreter.prototype = {
  PATTERNS: {
    "\x07": function(data) {
      // bell
    },

    "\x08": function(data) {
      this.terminal.bs();
    },

    "\x0a": function(data) {
      this.terminal.cursorDown();
    },

    "\x0d": function(data) {
      this.terminal.cr();
    },

    "\x0e": function(data) {
    },

    "\x0f": function(data) {
    },

    "\x82": function(data) { // Reserved (?)
    },

    "\x94": function(data) { // Cancel Character, ignore previous character
    },

    // 20 - 7e
    "([\x20-\x7e]|\xe2..|[\xc5\xc4].)+": function(data, match) {
      this.terminal.print(match[0]);
    },

    "\x1b\\(B": function(data) { // SCS (Set G0 Character SET)
    },

    "\x1b\\[(?:[0-9]+)?(?:;[0-9]+)*([\x40-\x7e])": function(data, match) {
      this.params = [];
      var re = /(\d+)/g;
      var m;

      while (m = re.exec(match[0])) {
        this.params.push(parseInt(m[1]));
      }

      this.n = this.params[0];
      this.m = this.params[1];

      this.handleCSI(match[1]);
    },

    "\x1b\\[\\?([\x30-\x3f]+)([hlsr])": function(data, match) { // private standards
      // h = Sets DEC/xterm specific mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#decmode)
      // l = Resets mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#mode)
      // 1001 + s = ?
      // 1001 + r = ?
      var modes = match[1].split(';');
      var action = match[2];
      var mode;

      for (var i=0; i<modes.length; i++) {
        mode = modes[i];

        if (mode == '1049') {
          if (action == 'h') {
            // Save cursor position, switch to alternate screen buffer, and clear screen.
            this.terminal.saveCursor();
            this.terminal.switchToAlternateBuffer();
            this.terminal.clearScreen();
          } else if (action == 'l') {
            // Clear screen, switch to normal screen buffer, and restore cursor position.
            this.terminal.clearScreen();
            this.terminal.switchToNormalBuffer();
            this.terminal.restoreCursor();
          }
        } else if (mode == '1002') {
          // 2002 + h / l = mouse tracking stuff
        } else if (mode == '1001') {
          // pbly sth with mouse/keys...
        } else if (mode == '1') {
          // 1 + h / l = cursor keys stuff
        } else if (mode == '47') {
          if (action == 'h') {
            this.terminal.switchToAlternateBuffer();
          } else if (action == 'l') {
            this.terminal.switchToNormalBuffer();
          }
        } else if (mode == '25') {
          if (action == 'h') {
            this.terminal.showCursor(true);
          } else if (action == 'l') {
            this.terminal.showCursor(false);
          }
        } else if (mode == '12') {
          if (action == 'h') {
            // blinking cursor
          } else if (action == 'l') {
            // steady cursor
          }
        } else {
          throw 'unknown mode: ' + mode + action;
        }
      }
    },

    "\x1b\x3d": function(data) { // DECKPAM - Set keypad to applications mode (ESCape instead of digits)
    },

    "\x1b\x3e": function(data) { // DECKPNM - Set keypad to numeric mode (digits intead of ESCape seq)
    },

    "\x1b\\\x5d[012]\x3b(?:.)*?\x07": function(data, match) { // OSC - Operating System Command (terminal title)
    },

    "\x1b\\[>c": function(data) { // Secondary Device Attribute request (?)
    },

    "\x1bP([^\\\\])*?\\\\": function(data) { // DCS, Device Control String
    },

    "\x1bM": function() {
      this.terminal.ri(this.n || 1);
    },

    "\x1b\x37": function(data) { // save cursor pos and char attrs
      this.terminal.saveCursor();
    },

    "\x1b\x38": function(data) { // restore cursor pos and char attrs
      this.terminal.restoreCursor();
    }
  },

  handleCSI: function(term) {
    switch(term) {
      case "@":
        this.terminal.reserveCharacters(this.n);
        break;
      case "A":
        this.terminal.cursorUp(this.n || 1);
        break;
      case "B":
        this.terminal.cursorDown(this.n || 1);
        break;
      case "C":
        this.terminal.cursorForward(this.n || 1);
        break;
      case "D":
        this.terminal.cursorBack(this.n || 1);
        break;
      case "H":
        this.terminal.setCursorPos(this.n || 1, this.m || 1);
        break;
      case "J":
        this.terminal.eraseData(this.n || 0);
        break;
      case "K":
        this.terminal.eraseLine(this.n || 0);
        break;
      case "L":
        this.terminal.insertLines(this.cursorY, this.n || 1);
        break;
      case "l": // l, Reset mode
        console.log("(TODO) reset: " + this.n);
        break;
      case "m":
        this.terminal.setSGR(this.params);
        break;
      case "r": // Set top and bottom margins (scroll region on VT100)
        break;
      default:
        throw 'no handler for CSI term: ' + term;
    }
  },

  compilePatterns: function() {
    this.COMPILED_PATTERNS = [];
    var regexp;

    for (re in this.PATTERNS) {
      regexp = new RegExp('^' + re);
      this.COMPILED_PATTERNS.push([regexp, this.PATTERNS[re]]);
    }
  },

  feed: function(data) {
    var match;
    var handler;

    while (data.length > 0) {
      match = handler = null;

      for (var i=0; i<this.COMPILED_PATTERNS.length; i++) {
        var pattern = this.COMPILED_PATTERNS[i];
        match = pattern[0].exec(data);
        if (match) {
          handler = pattern[1];
          break;
        }
      }

      if (handler) {
        handler.call(this, data, match);
        data = data.slice(match[0].length)
      } else {
        return data;
      }
    }

    return '';
  }
}

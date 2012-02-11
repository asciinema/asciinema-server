describe 'AsciiIo.VT', ->
  vt = renderer = data = undefined
  cols = 80
  lines = 24

  isSwallowed = (d) ->
    vt.sb = # will throw 'undefined is not a function' for anything else
      changes: ->
      clearChanges: ->

    expect(vt.feed(d || data)).toEqual(true)

  beforeEach ->
    renderer = new AsciiIo.TerminalView({ cols: cols, lines: lines })
    vt = new AsciiIo.VT(cols, lines, renderer)
    data = ''

  describe '#feed', ->
    it 'renders and clears buffer changes', ->
      changes = { someChanges: 'here' }
      spyOn vt.renderer, 'render'
      spyOn(vt.sb, 'changes').andReturn(changes)
      spyOn(vt.sb, 'clearChanges')

      vt.feed('')

      expect(vt.renderer.render).toHaveBeenCalledWith(changes, vt.sb.cursorX,
                                                      vt.sb.cursorY)
      expect(vt.sb.clearChanges).toHaveBeenCalled()

    describe 'C0 set control character', ->
      # A single character with an ASCII code within the ranges: 000 to 037 and
      # 200 to 237 octal, 00 - 1F and 80 - 9F hex.

      describe 'x07', ->
        it 'calls bell', ->
          data += '\x07'
          spyOn vt, 'bell'
          vt.feed(data)
          expect(vt.bell).toHaveBeenCalled()

      describe 'x08', ->
        it 'calls backspace', ->
          data += '\x08'
          spyOn vt.sb, 'backspace'
          vt.feed(data)
          expect(vt.sb.backspace).toHaveBeenCalled()

      describe 'x0a', ->
        it 'calls cursorDown(1)', ->
          data += '\x0a'
          spyOn vt.sb, 'cursorDown'
          vt.feed(data)
          expect(vt.sb.cursorDown).toHaveBeenCalledWith(1)

      describe 'x0d', ->
        it 'calls cr', ->
          data += '\x0d'
          spyOn vt.sb, 'cr'
          vt.feed(data)
          expect(vt.sb.cr).toHaveBeenCalled()

      describe 'other', ->
        it "is swallowed", ->
          for c in ['\x00', '\x09', '\x0e', '\x0f', '\x82', '\x94']
            isSwallowed(c)


    describe 'printable character', ->
      describe 'from ASCII range (0x20-0x7e)', ->
        it 'calls print', ->
          data += '\x20foobar\x7e'
          spyOn vt.sb, 'print'
          vt.feed(data)
          expect(vt.sb.print).toHaveBeenCalledWith(data)

      describe 'from Unicode', ->
        it 'calls print', ->
          data += '\xe2ab\xe2ZZ'
          spyOn vt.sb, 'print'
          vt.feed(data)
          expect(vt.sb.print).toHaveBeenCalledWith(data)

      describe 'from Unicode (really ???)', ->
        it 'calls print', ->
          data += '\xc2a\xc4b\xc5c'
          spyOn vt.sb, 'print'
          vt.feed(data)
          expect(vt.sb.print).toHaveBeenCalledWith(data)


    describe 'escape sequence', ->
      # 2 or 3 character string starting with ESCape. (Four or more character
      # strings are allowed but not defined.)

      beforeEach ->
        data += '\x1b'

      describe 'with C0 control nested inside another escape sequence', ->
        # C0 Control = 00-1F
        # Interpret the character, then resume processing the sequence.
        # Example: CR, LF, XON, and XOFF work as normal within an ESCape
        # sequence.

        # it 'aaa', ->
        #   data += '[1\x1b\x0dm'
        #   spyOn vt.sb, 'cr'
        #   spyOn vt.sb, 'setSGR'
        #   vt.feed(data)
        #   expect(vt.sb.cr).toHaveBeenCalled()
        #   expect(vt.sb.setSGR).toHaveBeenCalledWith([1])

      describe 'with intermediate', ->
        # Intermediate = 20-2F !"#$%&'()*+,-./
        # Expect zero or more intermediates, a parameter terminates a private
        # function, an alphabetic terminates a standard sequence.  Example: ESC
        # ( A defines standard character set, ESC ( 0 a DEC set.

        describe '(', ->

          beforeEach ->
            data += '('

          describe 'B', ->

            beforeEach ->
              data += 'B'

            it 'is swallowed', isSwallowed

        describe 'followed by parameter', ->
          # private function

        describe 'followed by an alphabetic', ->
          # standard sequence

      describe 'with parameter', ->
        # Parameter = 30-3F 0123456789:;<=>?
        # End of a private 2-character escape sequence.  Example: ESC = sets
        # special keypad mode, ESC > clears it.

        describe '7', ->
          beforeEach ->
            data += '7'

          it 'saves cursor', ->
            spyOn vt.sb, 'saveCursor'
            vt.feed(data)
            expect(vt.sb.saveCursor).toHaveBeenCalled()

        describe '8', ->
          beforeEach ->
            data += '8'

          it 'restores cursor', ->
            spyOn vt.sb, 'restoreCursor'
            vt.feed(data)
            expect(vt.sb.restoreCursor).toHaveBeenCalled()

        describe '=', ->
          beforeEach ->
            data += '='

          it 'is swallowed', isSwallowed

        describe '>', ->
          beforeEach ->
            data += '>'

          it 'is swallowed', isSwallowed

      describe 'with uppercase', ->
        # Uppercase = 40-5F @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
        # Translate it into a C1 control character and act on it.  Example: ESC
        # D does indexes down, ESC M indexes up. (CSI is special)

        describe 'M', ->
          # Reverse Index, go up one line, reverse scroll if necessary

          beforeEach ->
            data += 'M'

          it 'goes up 1 line', ->
            spyOn vt.sb, 'ri'
            vt.feed(data)
            expect(vt.sb.ri).toHaveBeenCalled()

        describe 'P', ->
          # Device Control String, terminated by ST

          beforeEach ->
            data += 'Pfoobar\\'

          it 'is swallowed', isSwallowed

        describe ']', ->
          # Operating system command

          # beforeEach ->
          #   vt = new AsciiIo.VT(cols, lines, renderer)
            # vt.sb = {} # will throw 'undefined is not a function'

          describe '0;...BELL', ->
            beforeEach ->
              data += ']0;foobar\x07'

            it 'is swallowed', isSwallowed

          describe '1;...BELL', ->
            beforeEach ->
              data += ']1;foobar\x07'

            it 'is swallowed', isSwallowed

          describe '2;...BELL', ->
            beforeEach ->
              data += ']2;foobar\x07'

            it 'is swallowed', isSwallowed


      describe 'with lowercase', ->
        # Lowercase = 60-7E `abcdefghijlkmnopqrstuvwxyz{|}~
        # End of a standard 2-character escape sequence.  Example: ESC c resets
        # the terminal.

      describe 'with delete', ->
        # Delete = 7F
        # Ignore it, and continue interpreting the ESCape sequence C1 and G1:
        # Treat the same as their 7-bit counterparts

      describe 'with control sequence', ->
        # A string starting with CSI (233 octal, 9B hex) or with ESC[
        # (Left-Bracket) and terminated by an alphabetic character.  Any number of
        # parameter characters (digits 0 to 9, semicolon, and question mark) may
        # appear within the Control Sequence.  The terminating character may be
        # preceded by an intermediate character (such as space).

        beforeEach ->
          data += '['

        describe 'buffering', ->
          # it 'allows parsing in chunks', ->
          #   spyOn vt, 'handleSGR'
          #   vt.feed(data)
          #   vt.feed('m')
          #   expect(vt.handleSGR).toHaveBeenCalled()

        describe '@', ->
          it 'calls reserveCharacters', ->
            data += '3@'
            spyOn vt.sb, 'reserveCharacters'
            vt.feed(data)
            expect(vt.sb.reserveCharacters).toHaveBeenCalledWith(3)

        describe 'A', ->
          it 'calls cursorUp(1) if no number given', ->
            data += 'A'
            spyOn vt.sb, 'cursorUp'
            vt.feed(data)
            expect(vt.sb.cursorUp).toHaveBeenCalledWith(1)

          it 'calls cursorUp(n) if number given', ->
            data += '3A'
            spyOn vt.sb, 'cursorUp'
            vt.feed(data)
            expect(vt.sb.cursorUp).toHaveBeenCalledWith(3)

        describe 'B', ->
          it 'calls cursorDown(1) if no number given', ->
            data += 'B'
            spyOn vt.sb, 'cursorDown'
            vt.feed(data)
            expect(vt.sb.cursorDown).toHaveBeenCalledWith(1)

          it 'calls cursorDown(n) if number given', ->
            data += '3B'
            spyOn vt.sb, 'cursorDown'
            vt.feed(data)
            expect(vt.sb.cursorDown).toHaveBeenCalledWith(3)

        describe 'C', ->
          it 'calls cursorForward(1) if no number given', ->
            data += 'C'
            spyOn vt.sb, 'cursorForward'
            vt.feed(data)
            expect(vt.sb.cursorForward).toHaveBeenCalledWith(1)

          it 'calls cursorForward(n) if number given', ->
            data += '3C'
            spyOn vt.sb, 'cursorForward'
            vt.feed(data)
            expect(vt.sb.cursorForward).toHaveBeenCalledWith(3)

        describe 'D', ->
          it 'calls cursorBack(1) if no number given', ->
            data += 'D'
            spyOn vt.sb, 'cursorBack'
            vt.feed(data)
            expect(vt.sb.cursorBack).toHaveBeenCalledWith(1)

          it 'calls cursorBack(n) if number given', ->
            data += '3D'
            spyOn vt.sb, 'cursorBack'
            vt.feed(data)
            expect(vt.sb.cursorBack).toHaveBeenCalledWith(3)

        describe 'G', ->
          it 'calls setCursorColumn(n)', ->
            data += '3G'
            spyOn vt.sb, 'setCursorColumn'
            vt.feed(data)
            expect(vt.sb.setCursorColumn).toHaveBeenCalledWith(3)

        describe 'H', ->
          it 'calls setCursorPos(n, m) when n and m given', ->
            data += '3;4H'
            spyOn vt.sb, 'setCursorPos'
            vt.feed(data)
            expect(vt.sb.setCursorPos).toHaveBeenCalledWith(3, 4)

          it 'calls setCursorPos(1, m) when no n given', ->
            data += ';3H'
            spyOn vt.sb, 'setCursorPos'
            vt.feed(data)
            expect(vt.sb.setCursorPos).toHaveBeenCalledWith(1, 3)

          it 'calls setCursorPos(n, 1) when no m given', ->
            data += '3;H'
            spyOn vt.sb, 'setCursorPos'
            vt.feed(data)
            expect(vt.sb.setCursorPos).toHaveBeenCalledWith(3, 1)

          it 'calls setCursorPos(n, 1) when no m given (no semicolon)', ->
            data += '3H'
            spyOn vt.sb, 'setCursorPos'
            vt.feed(data)
            expect(vt.sb.setCursorPos).toHaveBeenCalledWith(3, 1)

          it 'calls setCursorPos(1, 1) when no n nor m given', ->
            data += 'H'
            spyOn vt.sb, 'setCursorPos'
            vt.feed(data)
            expect(vt.sb.setCursorPos).toHaveBeenCalledWith(1, 1)

        describe 'J', ->
          it 'calls eraseData(0) when no n given', ->
            data += 'J'
            spyOn vt.sb, 'eraseData'
            vt.feed(data)
            expect(vt.sb.eraseData).toHaveBeenCalledWith(0)

          it 'calls eraseData(n) when n given', ->
            data += '3J'
            spyOn vt.sb, 'eraseData'
            vt.feed(data)
            expect(vt.sb.eraseData).toHaveBeenCalledWith(3)

        describe 'K', ->
          it 'calls eraseInLine(0) when no n given', ->
            data += 'K'
            spyOn vt.sb, 'eraseInLine'
            vt.feed(data)
            expect(vt.sb.eraseInLine).toHaveBeenCalledWith(0)

          it 'calls eraseInLine(n) when n given', ->
            data += '3K'
            spyOn vt.sb, 'eraseInLine'
            vt.feed(data)
            expect(vt.sb.eraseInLine).toHaveBeenCalledWith(3)

        describe 'L', ->
          it 'calls insertLines(1) when no n given', ->
            data += 'L'
            spyOn vt.sb, 'insertLines'
            vt.feed(data)
            expect(vt.sb.insertLines).toHaveBeenCalledWith(1)

          it 'calls insertLines(n) when n given', ->
            data += '3L'
            spyOn vt.sb, 'insertLines'
            vt.feed(data)
            expect(vt.sb.insertLines).toHaveBeenCalledWith(3)

        describe 'M', ->
          it 'calls deleteLines(1) when no n given', ->
            data += 'M'
            spyOn vt.sb, 'deleteLines'
            vt.feed(data)
            expect(vt.sb.deleteLines).toHaveBeenCalledWith(1)

          it 'calls deleteLines(n) when n given', ->
            data += '3M'
            spyOn vt.sb, 'deleteLines'
            vt.feed(data)
            expect(vt.sb.deleteLines).toHaveBeenCalledWith(3)

        describe 'd', ->
          it 'calls setCursorLine(n)', ->
            data += '3d'
            spyOn vt.sb, 'setCursorLine'
            vt.feed(data)
            expect(vt.sb.setCursorLine).toHaveBeenCalledWith(3)

        describe 'm', ->
          it 'calls handleSGR([n, m, ...]) when n and m given', ->
            data += '1;4;33m'
            spyOn vt, 'handleSGR'
            vt.feed(data)
            expect(vt.handleSGR).toHaveBeenCalledWith([1, 4, 33])

          it 'calls handleSGR([]) when no n nor m given', ->
            data += 'm'
            spyOn vt, 'handleSGR'
            vt.feed(data)
            expect(vt.handleSGR).toHaveBeenCalledWith([])

        describe 'P', ->
          it 'calls deleteCharacter(1) when no n given', ->
            data += 'P'
            spyOn vt.sb, 'deleteCharacter'
            vt.feed(data)
            expect(vt.sb.deleteCharacter).toHaveBeenCalledWith(1)

          it 'calls deleteCharacter(n) when n given', ->
            data += '3P'
            spyOn vt.sb, 'deleteCharacter'
            vt.feed(data)
            expect(vt.sb.deleteCharacter).toHaveBeenCalledWith(3)

        describe 'c', ->
          beforeEach ->
            data += '>c'

          it 'is swallowed', isSwallowed

        describe 'from private standards', ->
          # first character after CSI is one of: " < = > (074-077 octal, 3C-3F )

        describe 'DEC/xterm specific', ->
          describe '$~', ->
            beforeEach ->
              data += '$~'

            it 'is swallowed', isSwallowed

          describe '?', ->
            beforeEach ->
              data += '?'

            describe '1h', ->
              beforeEach ->
                data += '1h'

              it 'is swallowed', isSwallowed

            describe '25h', ->
              beforeEach ->
                data += '25h'

              it 'shows cursor', ->
                spyOn vt.renderer, 'showCursor'
                vt.feed(data)
                expect(vt.renderer.showCursor).toHaveBeenCalledWith(true)

            describe '25l', ->
              beforeEach ->
                data += '25l'

              it 'hides cursor', ->
                spyOn vt.renderer, 'showCursor'
                vt.feed(data)
                expect(vt.renderer.showCursor).toHaveBeenCalledWith(false)

            describe '47h', ->
              beforeEach ->
                data += '47h'

              it 'switches to alternate buffer', ->
                spyOn vt.sb, 'switchToAlternateBuffer'
                vt.feed(data)
                expect(vt.sb.switchToAlternateBuffer).toHaveBeenCalled()

            describe '47l', ->
              beforeEach ->
                data += '47l'

              it 'switches to normal buffer', ->
                spyOn vt.sb, 'switchToNormalBuffer'
                vt.feed(data)
                expect(vt.sb.switchToNormalBuffer).toHaveBeenCalled()

            describe '1049h', ->
              beforeEach ->
                data += '1049h'

              it 'saves cursor position, switches to alternate buffer and clear screen', ->
                spyOn vt.sb, 'saveCursor'
                spyOn vt.sb, 'switchToAlternateBuffer'
                spyOn vt.sb, 'clear'
                vt.feed(data)
                expect(vt.sb.saveCursor).toHaveBeenCalled()
                expect(vt.sb.switchToAlternateBuffer).toHaveBeenCalled()
                expect(vt.sb.clear).toHaveBeenCalled()

            describe '1049l', ->
              beforeEach ->
                data += '1049l'

              it 'clears screen, switches to normal buffer and restores cursor position', ->
                spyOn vt.sb, 'clear'
                spyOn vt.sb, 'switchToNormalBuffer'
                spyOn vt.sb, 'restoreCursor'
                vt.feed(data)
                expect(vt.sb.clear).toHaveBeenCalled()
                expect(vt.sb.switchToNormalBuffer).toHaveBeenCalled()
                expect(vt.sb.restoreCursor).toHaveBeenCalled()


  describe '#handleSGR', ->
    numbers = undefined

    it 'resets brush for 0', ->
      spyOn vt.sb, 'setBrush'

      numbers = [31]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [0]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets bright attr for 1', ->
      numbers = [1]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bright: true })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets underline attr for 4', ->
      numbers = [4]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ underline: true })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets underline attr for 24', ->
      spyOn vt.sb, 'setBrush'

      numbers = [31, 4]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1, underline: true })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [24]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets foreground for 30-37', ->
      numbers = [32]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 2 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets foreground for 38;5;x', ->
      numbers = [38, 5, 100]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 100 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets foreground for 39', ->
      spyOn vt.sb, 'setBrush'

      numbers = [32]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 2 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [39]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets background for 40-47', ->
      numbers = [42]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 2 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets background for 48;5;x', ->
      numbers = [48, 5, 200]
      spyOn vt.sb, 'setBrush'
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 200 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets background for 49', ->
      spyOn vt.sb, 'setBrush'

      numbers = [42]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 2 })
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [49]
      vt.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(vt.sb.setBrush).toHaveBeenCalledWith(expectedBrush)


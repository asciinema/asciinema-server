describe AsciiIo.AnsiInterpreter, ->
  interpreter = screenBuffer = data = undefined
  cols = 80
  lines = 24

  isSwallowed = (d) ->
    screenBuffer = {} # will throw 'undefined is not a function'
    interpreter = new AsciiIo.AnsiInterpreter(screenBuffer)
    expect(interpreter.feed(d || data)).toEqual(true)

  beforeEach ->
    screenBuffer = new AsciiIo.ScreenBuffer(cols, lines)
    interpreter = new AsciiIo.AnsiInterpreter(screenBuffer)
    data = ''

  describe '#feed', ->
    describe 'C0 set control character', ->
      # A single character with an ASCII code within the ranges: 000 to 037 and
      # 200 to 237 octal, 00 - 1F and 80 - 9F hex.

      describe 'x07', ->
        it 'calls bell', ->
          data += '\x07'
          spyOn screenBuffer, 'bell'
          interpreter.feed(data)
          expect(screenBuffer.bell).toHaveBeenCalled()

      describe 'x08', ->
        it 'calls backspace', ->
          data += '\x08'
          spyOn screenBuffer, 'backspace'
          interpreter.feed(data)
          expect(screenBuffer.backspace).toHaveBeenCalled()

      describe 'x0a', ->
        it 'calls cursorDown(1)', ->
          data += '\x0a'
          spyOn screenBuffer, 'cursorDown'
          interpreter.feed(data)
          expect(screenBuffer.cursorDown).toHaveBeenCalledWith(1)

      describe 'x0d', ->
        it 'calls cr', ->
          data += '\x0d'
          spyOn screenBuffer, 'cr'
          interpreter.feed(data)
          expect(screenBuffer.cr).toHaveBeenCalled()

      describe 'other', ->
        it "is swallowed", ->
          for c in ['\x00', '\x09', '\x0e', '\x0f', '\x82', '\x94']
            isSwallowed(c)


    describe 'printable character', ->
      describe 'from ASCII range (0x20-0x7e)', ->
        it 'calls print', ->
          data += '\x20foobar\x7e'
          spyOn screenBuffer, 'print'
          interpreter.feed(data)
          expect(screenBuffer.print).toHaveBeenCalledWith(data)

      describe 'from Unicode', ->
        it 'calls print', ->
          data += '\xe2ab\xe2ZZ'
          spyOn screenBuffer, 'print'
          interpreter.feed(data)
          expect(screenBuffer.print).toHaveBeenCalledWith(data)

      describe 'from Unicode (really ???)', ->
        it 'calls print', ->
          data += '\xc2a\xc4b\xc5c'
          spyOn screenBuffer, 'print'
          interpreter.feed(data)
          expect(screenBuffer.print).toHaveBeenCalledWith(data)


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
        #   spyOn screenBuffer, 'cr'
        #   spyOn screenBuffer, 'setSGR'
        #   interpreter.feed(data)
        #   expect(screenBuffer.cr).toHaveBeenCalled()
        #   expect(screenBuffer.setSGR).toHaveBeenCalledWith([1])

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
            spyOn screenBuffer, 'saveCursor'
            interpreter.feed(data)
            expect(screenBuffer.saveCursor).toHaveBeenCalled()

        describe '8', ->
          beforeEach ->
            data += '8'

          it 'restores cursor', ->
            spyOn screenBuffer, 'restoreCursor'
            interpreter.feed(data)
            expect(screenBuffer.restoreCursor).toHaveBeenCalled()

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
            spyOn screenBuffer, 'ri'
            interpreter.feed(data)
            expect(screenBuffer.ri).toHaveBeenCalled()

        describe 'P', ->
          # Device Control String, terminated by ST

          beforeEach ->
            data += 'Pfoobar\\'

          it 'is swallowed', isSwallowed

        describe ']', ->
          # Operating system command

          beforeEach ->
            screenBuffer = {} # will throw 'undefined is not a function'
            interpreter = new AsciiIo.AnsiInterpreter(screenBuffer)

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
          #   spyOn interpreter, 'handleSGR'
          #   interpreter.feed(data)
          #   interpreter.feed('m')
          #   expect(interpreter.handleSGR).toHaveBeenCalled()

        describe '@', ->
          it 'calls reserveCharacters', ->
            data += '3@'
            spyOn screenBuffer, 'reserveCharacters'
            interpreter.feed(data)
            expect(screenBuffer.reserveCharacters).toHaveBeenCalledWith(3)

        describe 'A', ->
          it 'calls cursorUp(1) if no number given', ->
            data += 'A'
            spyOn screenBuffer, 'cursorUp'
            interpreter.feed(data)
            expect(screenBuffer.cursorUp).toHaveBeenCalledWith(1)

          it 'calls cursorUp(n) if number given', ->
            data += '3A'
            spyOn screenBuffer, 'cursorUp'
            interpreter.feed(data)
            expect(screenBuffer.cursorUp).toHaveBeenCalledWith(3)

        describe 'B', ->
          it 'calls cursorDown(1) if no number given', ->
            data += 'B'
            spyOn screenBuffer, 'cursorDown'
            interpreter.feed(data)
            expect(screenBuffer.cursorDown).toHaveBeenCalledWith(1)

          it 'calls cursorDown(n) if number given', ->
            data += '3B'
            spyOn screenBuffer, 'cursorDown'
            interpreter.feed(data)
            expect(screenBuffer.cursorDown).toHaveBeenCalledWith(3)

        describe 'C', ->
          it 'calls cursorForward(1) if no number given', ->
            data += 'C'
            spyOn screenBuffer, 'cursorForward'
            interpreter.feed(data)
            expect(screenBuffer.cursorForward).toHaveBeenCalledWith(1)

          it 'calls cursorForward(n) if number given', ->
            data += '3C'
            spyOn screenBuffer, 'cursorForward'
            interpreter.feed(data)
            expect(screenBuffer.cursorForward).toHaveBeenCalledWith(3)

        describe 'D', ->
          it 'calls cursorBack(1) if no number given', ->
            data += 'D'
            spyOn screenBuffer, 'cursorBack'
            interpreter.feed(data)
            expect(screenBuffer.cursorBack).toHaveBeenCalledWith(1)

          it 'calls cursorBack(n) if number given', ->
            data += '3D'
            spyOn screenBuffer, 'cursorBack'
            interpreter.feed(data)
            expect(screenBuffer.cursorBack).toHaveBeenCalledWith(3)

        describe 'G', ->
          it 'calls setCursorColumn(n)', ->
            data += '3G'
            spyOn screenBuffer, 'setCursorColumn'
            interpreter.feed(data)
            expect(screenBuffer.setCursorColumn).toHaveBeenCalledWith(3)

        describe 'H', ->
          it 'calls setCursorPos(n, m) when n and m given', ->
            data += '3;4H'
            spyOn screenBuffer, 'setCursorPos'
            interpreter.feed(data)
            expect(screenBuffer.setCursorPos).toHaveBeenCalledWith(3, 4)

          it 'calls setCursorPos(1, m) when no n given', ->
            data += ';3H'
            spyOn screenBuffer, 'setCursorPos'
            interpreter.feed(data)
            expect(screenBuffer.setCursorPos).toHaveBeenCalledWith(1, 3)

          it 'calls setCursorPos(n, 1) when no m given', ->
            data += '3;H'
            spyOn screenBuffer, 'setCursorPos'
            interpreter.feed(data)
            expect(screenBuffer.setCursorPos).toHaveBeenCalledWith(3, 1)

          it 'calls setCursorPos(n, 1) when no m given (no semicolon)', ->
            data += '3H'
            spyOn screenBuffer, 'setCursorPos'
            interpreter.feed(data)
            expect(screenBuffer.setCursorPos).toHaveBeenCalledWith(3, 1)

          it 'calls setCursorPos(1, 1) when no n nor m given', ->
            data += 'H'
            spyOn screenBuffer, 'setCursorPos'
            interpreter.feed(data)
            expect(screenBuffer.setCursorPos).toHaveBeenCalledWith(1, 1)

        describe 'J', ->
          it 'calls eraseData(0) when no n given', ->
            data += 'J'
            spyOn screenBuffer, 'eraseData'
            interpreter.feed(data)
            expect(screenBuffer.eraseData).toHaveBeenCalledWith(0)

          it 'calls eraseData(n) when n given', ->
            data += '3J'
            spyOn screenBuffer, 'eraseData'
            interpreter.feed(data)
            expect(screenBuffer.eraseData).toHaveBeenCalledWith(3)

        describe 'K', ->
          it 'calls eraseInLine(0) when no n given', ->
            data += 'K'
            spyOn screenBuffer, 'eraseInLine'
            interpreter.feed(data)
            expect(screenBuffer.eraseInLine).toHaveBeenCalledWith(0)

          it 'calls eraseInLine(n) when n given', ->
            data += '3K'
            spyOn screenBuffer, 'eraseInLine'
            interpreter.feed(data)
            expect(screenBuffer.eraseInLine).toHaveBeenCalledWith(3)

        describe 'L', ->
          it 'calls insertLines(1) when no n given', ->
            data += 'L'
            spyOn screenBuffer, 'insertLines'
            interpreter.feed(data)
            expect(screenBuffer.insertLines).toHaveBeenCalledWith(1)

          it 'calls insertLines(n) when n given', ->
            data += '3L'
            spyOn screenBuffer, 'insertLines'
            interpreter.feed(data)
            expect(screenBuffer.insertLines).toHaveBeenCalledWith(3)

        describe 'M', ->
          it 'calls deleteLines(1) when no n given', ->
            data += 'M'
            spyOn screenBuffer, 'deleteLines'
            interpreter.feed(data)
            expect(screenBuffer.deleteLines).toHaveBeenCalledWith(1)

          it 'calls deleteLines(n) when n given', ->
            data += '3M'
            spyOn screenBuffer, 'deleteLines'
            interpreter.feed(data)
            expect(screenBuffer.deleteLines).toHaveBeenCalledWith(3)

        describe 'd', ->
          it 'calls setCursorLine(n)', ->
            data += '3d'
            spyOn screenBuffer, 'setCursorLine'
            interpreter.feed(data)
            expect(screenBuffer.setCursorLine).toHaveBeenCalledWith(3)

        describe 'm', ->
          it 'calls handleSGR([n, m, ...]) when n and m given', ->
            data += '1;4;33m'
            spyOn interpreter, 'handleSGR'
            interpreter.feed(data)
            expect(interpreter.handleSGR).toHaveBeenCalledWith([1, 4, 33])

          it 'calls handleSGR([]) when no n nor m given', ->
            data += 'm'
            spyOn interpreter, 'handleSGR'
            interpreter.feed(data)
            expect(interpreter.handleSGR).toHaveBeenCalledWith([])

        describe 'P', ->
          it 'calls deleteCharacter(1) when no n given', ->
            data += 'P'
            spyOn screenBuffer, 'deleteCharacter'
            interpreter.feed(data)
            expect(screenBuffer.deleteCharacter).toHaveBeenCalledWith(1)

          it 'calls deleteCharacter(n) when n given', ->
            data += '3P'
            spyOn screenBuffer, 'deleteCharacter'
            interpreter.feed(data)
            expect(screenBuffer.deleteCharacter).toHaveBeenCalledWith(3)

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
                spyOn screenBuffer, 'showCursor'
                interpreter.feed(data)
                expect(screenBuffer.showCursor).toHaveBeenCalledWith(true)

            describe '25l', ->
              beforeEach ->
                data += '25l'

              it 'hides cursor', ->
                spyOn screenBuffer, 'showCursor'
                interpreter.feed(data)
                expect(screenBuffer.showCursor).toHaveBeenCalledWith(false)

            describe '47h', ->
              beforeEach ->
                data += '47h'

              it 'switches to alternate buffer', ->
                spyOn screenBuffer, 'switchToAlternateBuffer'
                interpreter.feed(data)
                expect(screenBuffer.switchToAlternateBuffer).toHaveBeenCalled()

            describe '47l', ->
              beforeEach ->
                data += '47l'

              it 'switches to normal buffer', ->
                spyOn screenBuffer, 'switchToNormalBuffer'
                interpreter.feed(data)
                expect(screenBuffer.switchToNormalBuffer).toHaveBeenCalled()

            describe '1049h', ->
              beforeEach ->
                data += '1049h'

              it 'saves cursor position, switches to alternate buffer and clear screen', ->
                spyOn screenBuffer, 'saveCursor'
                spyOn screenBuffer, 'switchToAlternateBuffer'
                spyOn screenBuffer, 'clear'
                interpreter.feed(data)
                expect(screenBuffer.saveCursor).toHaveBeenCalled()
                expect(screenBuffer.switchToAlternateBuffer).toHaveBeenCalled()
                expect(screenBuffer.clear).toHaveBeenCalled()

            describe '1049l', ->
              beforeEach ->
                data += '1049l'

              it 'clears screen, switches to normal buffer and restores cursor position', ->
                spyOn screenBuffer, 'clear'
                spyOn screenBuffer, 'switchToNormalBuffer'
                spyOn screenBuffer, 'restoreCursor'
                interpreter.feed(data)
                expect(screenBuffer.clear).toHaveBeenCalled()
                expect(screenBuffer.switchToNormalBuffer).toHaveBeenCalled()
                expect(screenBuffer.restoreCursor).toHaveBeenCalled()


  describe '#handleSGR', ->
    numbers = undefined

    it 'resets brush for 0', ->
      spyOn screenBuffer, 'setBrush'

      numbers = [31]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [0]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets bright attr for 1', ->
      numbers = [1]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bright: true })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets underline attr for 4', ->
      numbers = [4]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ underline: true })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets underline attr for 24', ->
      spyOn screenBuffer, 'setBrush'

      numbers = [31, 4]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1, underline: true })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [24]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 1 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets foreground for 30-37', ->
      numbers = [32]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 2 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets foreground for 38;5;x', ->
      numbers = [38, 5, 100]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 100 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets foreground for 39', ->
      spyOn screenBuffer, 'setBrush'

      numbers = [32]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ fg: 2 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [39]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets background for 40-47', ->
      numbers = [42]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 2 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'sets background for 48;5;x', ->
      numbers = [48, 5, 200]
      spyOn screenBuffer, 'setBrush'
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 200 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

    it 'unsets background for 49', ->
      spyOn screenBuffer, 'setBrush'

      numbers = [42]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({ bg: 2 })
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)

      numbers = [49]
      interpreter.handleSGR(numbers)
      expectedBrush = AsciiIo.Brush.create({})
      expect(screenBuffer.setBrush).toHaveBeenCalledWith(expectedBrush)


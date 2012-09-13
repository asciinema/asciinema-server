describe 'AsciiIo.AnsiInterpreter', ->
  data = interpreter = calls = checkNumber = undefined

  callback = (action, args...) -> calls.push arguments

  parse = (data, expectedRest) ->
    rest = interpreter.parse data
    if arguments.length is 2
      expect(rest).toEqual expectedRest

  expectCall = (args...) ->
    n = checkNumber
    checkNumber += 1
    console.log calls[n]
    expect(calls[n]).toEqual args

  expectNoCall = ->
    console.log calls[0]
    expect(calls.length).toEqual 0

  isSwallowed = ->
    parse data, ''
    expectNoCall()

  beforeEach ->
    calls = []
    checkNumber = 0
    interpreter = new AsciiIo.AnsiInterpreter callback

  describe '#parse', ->

    it 'returns not parsed data', ->
      parse '\x1b', '\x1b'
      expectNoCall()

    it 'returns empty string if all data was parsed', ->
      parse 'abc def', ''

    describe 'C0 set control character', ->
      # A single character with an ASCII code within the ranges: 000 to 037 and
      # 200 to 237 octal, 00 - 1F and 80 - 9F hex.

      describe 'x07', ->
        it 'calls bell', ->
          parse '\x07'
          expectCall 'bell'

      describe 'x08', ->
        it 'calls backspace', ->
          parse '\x08'
          expectCall 'backspace'

      describe 'x09', ->
        it 'calls goToNextHorizontalTabStop', ->
          parse '\x09'
          expectCall 'goToNextHorizontalTabStop'

      describe 'x0a', ->
        it 'calls lineFeed', ->
          parse '\x0a'
          expectCall 'lineFeed'

      describe 'x0b', ->
        it 'calls verticalTab', ->
          parse '\x0b'
          expectCall 'verticalTab'

      describe 'x0c', ->
        it 'calls formFeed', ->
          parse '\x0c'
          expectCall 'formFeed'

      describe 'x0d', ->
        it 'calls carriageReturn', ->
          parse '\x0d'
          expectCall 'carriageReturn'

      describe 'x84', ->
        it 'calls index', ->
          parse '\x84'
          expectCall 'index'

      describe 'x85', ->
        it 'calls newLine', ->
          parse '\x85'
          expectCall 'newLine'

      describe 'x88', ->
        it 'calls setHorizontalTabStop', ->
          parse '\x88'
          expectCall 'setHorizontalTabStop'

      describe 'x8d', ->
        it 'calls reverseIndex', ->
          parse '\x8d'
          expectCall 'reverseIndex'

      describe 'other', ->
        it "is swallowed", ->
          for c in ['\x00', '\x0e', '\x0f', '\x82', '\x94']
            parse c, ''
            expectNoCall()

    describe 'printable character', ->

      describe 'from ASCII range (0x20-0x7e)', ->
        it 'calls print', ->
          parse '\x20foobar\x7e', ''
          expectCall 'print', '\x20foobar\x7e'

      describe 'from Unicode', ->
        it 'calls print', ->
          parse '\xe2ab\xe8ZZ', ''
          expectCall 'print', '\xe2ab\xe8ZZ'

          parse '\xc2\x09\xc4b\xc5c', ''
          expectCall 'print', '\xc2\x09\xc4b\xc5c'

          parse '\xa1A\xc9\xfe', ''
          expectCall 'print', '\xa1A\xc9\xfe'

    describe 'escape sequence', ->
      # 2 or 3 character string starting with ESCape. (Four or more character
      # strings are allowed but not defined.)

      beforeEach ->
        data = '\x1b'

      describe 'with C0 control nested inside another escape sequence', ->
        # C0 Control = 00-1F
        # Interpret the character, then resume processing the sequence.
        # Example: CR, LF, XON, and XOFF work as normal within an ESCape
        # sequence.

        # it 'stops interpreting current seq and handles nested C0 control char', ->
        #   data += '[1\x1b\x0dm'
        #   parse data, ''
        #   expectCall 'cr'
        #   expectCall 'updateBrush', bright: true

      describe 'with intermediate', ->
        # Intermediate = 20-2F !"#$%&'()*+,-./
        # Expect zero or more intermediates, a parameter terminates a private
        # function, an alphabetic terminates a standard sequence.  Example: ESC
        # ( A defines standard character set, ESC ( 0 a DEC set.

        describe '(', ->

          beforeEach ->
            data += '('

          describe 'A', ->

            beforeEach ->
              data += 'A'

            it 'calls setUkCharset', ->
              parse data
              expectCall 'setUkCharset'

          describe 'B', ->

            beforeEach ->
              data += 'B'

            it 'calls setUsCharset', ->
              parse data
              expectCall 'setUsCharset'

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

          it 'saves terminal state', ->
            parse data
            expectCall 'saveTerminalState'

        describe '8', ->
          beforeEach ->
            data += '8'

          it 'restores terminal state', ->
            parse data
            expectCall 'restoreTerminalState'

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
            parse data
            expectCall 'reverseIndex'

        describe 'P', ->
          # Device Control String, terminated by ST

          beforeEach ->
            data += 'Pfoobar\\'

          # it 'is swallowed', isSwallowed

        describe ']', ->
          # Operating system command

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

        describe '@', ->
          it 'calls reserveCharacters', ->
            data += '3@'
            parse data
            expectCall 'reserveCharacters', 3

        describe 'A', ->
          it 'calls priorRow(1) if no number given', ->
            data += 'A'
            parse data
            expectCall 'priorRow', 1

          it 'calls priorRow(n) if number given', ->
            data += '3A'
            parse data
            expectCall 'priorRow', 3

        describe 'B', ->
          it 'calls nextRow(1) if no number given', ->
            data += 'B'
            parse data
            expectCall 'nextRow', 1

          it 'calls nextRow(n) if number given', ->
            data += '3B'
            parse data
            expectCall 'nextRow', 3

        describe 'C', ->
          it 'calls nextColumn(1) if no number given', ->
            data += 'C'
            parse data
            expectCall 'nextColumn', 1

          it 'calls nextColumn(n) if number given', ->
            data += '3C'
            parse data
            expectCall 'nextColumn', 3

        describe 'D', ->
          it 'calls priorColumn(1) if no number given', ->
            data += 'D'
            parse data
            expectCall 'priorColumn', 1

          it 'calls priorColumn(n) if number given', ->
            data += '3D'
            parse data
            expectCall 'priorColumn', 3

        describe 'G', ->
          it 'calls goToColumn(n)', ->
            data += '3G'
            parse data
            expectCall 'goToColumn', 3

        describe 'H', ->
          it 'calls goToRowAndColumn(n, m) when n and m given', ->
            data += '3;4H'
            parse data
            expectCall 'goToRowAndColumn', 3, 4

          it 'calls goToRowAndColumn(1, m) when no n given', ->
            data += ';3H'
            parse data
            expectCall 'goToRowAndColumn', 1, 3

          it 'calls goToRowAndColumn(n, 1) when no m given', ->
            data += '3;H'
            parse data
            expectCall 'goToRowAndColumn', 3, 1

          it 'calls goToRowAndColumn(n, 1) when no m given (no semicolon)', ->
            data += '3H'
            parse data
            expectCall 'goToRowAndColumn', 3, 1

          it 'calls goToRowAndColumn(1, 1) when no n nor m given', ->
            data += 'H'
            parse data
            expectCall 'goToRowAndColumn', 1, 1

        describe 'J', ->
          it 'calls eraseToScreenEnd when no n given', ->
            data += 'J'
            parse data
            expectCall 'eraseToScreenEnd'

          it 'calls eraseToScreenEnd when 0 given', ->
            data += '0J' # TODO check if it's 0 or 3
            parse data
            expectCall 'eraseToScreenEnd'

          it 'calls eraseFromScreenStart when 1 given', ->
            data += '1J'
            parse data
            expectCall 'eraseFromScreenStart'

          it 'calls eraseScreen when 2 given', ->
            data += '2J'
            parse data
            expectCall 'eraseScreen'

        describe 'K', ->
          it 'calls eraseToRowEnd when no n given', ->
            data += 'K'
            parse data
            expectCall 'eraseToRowEnd'

          it 'calls eraseToRowEnd when 0 given', ->
            data += '0K' # TODO: check if its 0 or 3
            parse data
            expectCall 'eraseToRowEnd'

          it 'calls eraseFromRowStart when 1 given', ->
            data += '1K'
            parse data
            expectCall 'eraseFromRowStart'

          it 'calls eraseRow when 2 given', ->
            data += '2K'
            parse data
            expectCall 'eraseRow'

        describe 'L', ->
          it 'calls insertLines(1) when no n given', ->
            data += 'L'
            parse data
            expectCall 'insertLines', 1

          it 'calls insertLines(n) when n given', ->
            data += '3L'
            parse data
            expectCall 'insertLines', 3

        describe 'M', ->
          it 'calls deleteLines(1) when no n given', ->
            data += 'M'
            parse data
            expectCall 'deleteLines', 1

          it 'calls deleteLines(n) when n given', ->
            data += '3M'
            parse data
            expectCall 'deleteLines', 3

        describe 'd', ->
          it 'calls goToRow(n)', ->
            data += '3d'
            parse data
            expectCall 'goToRow', 3

        describe 'm', ->
          it 'calls handleSGR([n, m, ...]) when n and m given', ->
            data += '1;4;33m'
            spyOn interpreter, 'handleSGR'
            parse data
            expect(interpreter.handleSGR).toHaveBeenCalledWith([1, 4, 33])

          it 'calls handleSGR([]) when no n nor m given', ->
            data += 'm'
            spyOn interpreter, 'handleSGR'
            parse data
            expect(interpreter.handleSGR).toHaveBeenCalledWith([])

        describe 'P', ->
          it 'calls deleteCharacters(1) when no n given', ->
            data += 'P'
            parse data
            expectCall 'deleteCharacters', 1

          it 'calls deleteCharacters(n) when n given', ->
            data += '3P'
            parse data
            expectCall 'deleteCharacters', 3

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
                parse data
                expectCall 'showCursor'

            describe '25l', ->
              beforeEach ->
                data += '25l'

              it 'hides cursor', ->
                parse data
                expectCall 'hideCursor'

            describe '47h', ->
              beforeEach ->
                data += '47h'

              it 'switches to alternate buffer', ->
                parse data
                expectCall 'switchToAlternateBuffer'

            describe '47l', ->
              beforeEach ->
                data += '47l'

              it 'switches to normal buffer', ->
                parse data
                expectCall 'switchToNormalBuffer'

            describe '1049h', ->
              beforeEach ->
                data += '1049h'

              it 'saves cursor position, switches to alternate buffer and clear screen', ->
                parse data
                expectCall 'switchToAlternateBuffer'
                expectCall 'eraseScreen'

            describe '1049l', ->
              beforeEach ->
                data += '1049l'

              it 'clears screen, switches to normal buffer and restores cursor position', ->
                parse data
                expectCall 'eraseScreen'
                expectCall 'switchToNormalBuffer'

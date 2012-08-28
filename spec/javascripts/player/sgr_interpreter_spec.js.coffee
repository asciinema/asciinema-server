describe 'AsciiIo.SgrInterpreter', ->
  interpreter = new AsciiIo.SgrInterpreter

  expectChange = (numbers, hash) ->
    attrs = interpreter.parse numbers
    expect(attrs).toEqual hash

  describe '#parse', ->

    it 'resets brush for 0', ->
      expectChange [0], AsciiIo.Brush.default().attributes()

    it 'sets bright attr for 1', ->
      expectChange [1], bright: true

    it 'sets italic attr for 3', ->
      expectChange [3], italic: true

    it 'sets underline attr for 4', ->
      expectChange [4], underline: true

    it 'sets blink attr for 5', ->
      expectChange [5], blink: true

    it 'unsets italic for 23', ->
      expectChange [23], italic: false

    it 'unsets underline attr for 24', ->
      expectChange [24], underline: false

    it 'unsets blink attr for 25', ->
      expectChange [25], blink: false

    it 'sets foreground for 30-37', ->
      expectChange [30], fg: 0
      expectChange [32], fg: 2
      expectChange [37], fg: 7

    it 'sets foreground for 38;5;x', ->
      expectChange [38, 5, 100], fg: 100

    it 'resets foreground for 39', ->
      expectChange [39], fg: undefined

    it 'sets background for 40-47', ->
      expectChange [40], bg: 0
      expectChange [44], bg: 4
      expectChange [47], bg: 7

    it 'sets background for 48;5;x', ->
      expectChange [48, 5, 200], bg: 200

    it 'resets background for 49', ->
      expectChange [49], bg: undefined

    it 'sets foreground for 90-97', ->
      expectChange [90], fg: 0
      expectChange [93], fg: 3
      expectChange [97], fg: 7

    it 'sets background for 100-107', ->
      expectChange [100], bg: 0
      expectChange [103], bg: 3
      expectChange [107], bg: 7

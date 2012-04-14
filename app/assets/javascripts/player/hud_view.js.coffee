class AsciiIo.HudView extends Backbone.View
  tagName: 'pre'
  className: 'hud'

  events:
    'click .toggle': 'togglePlay'

  initialize: (options) ->
    @duration = undefined
    @cols = options.cols
    @lastArrowWidth = undefined
    @calculateElementWidths()
    @createChildViews()

  calculateElementWidths: ->
    @toggleWidth = 4
    @timeWidth = 7
    @progressWidth = @cols - @toggleWidth - @timeWidth

  createChildViews: ->
    toggle   = '<span class="toggle"> <span class="play">=></span><span class="pause">||</span> '
    progress = '<span class="progress">'
    time     = '<span class="time">'

    @$el.append(toggle)
    @$el.append(progress)
    @$el.append(time)

  setDuration: (@duration) ->

  togglePlay: ->
    @trigger('hud-play-click')

  onPause: ->
    @$('.toggle').addClass('paused')

  onResume: ->
    @$('.toggle').removeClass('paused')

  updateTime: (time) ->
    @$('.time').html(@formattedTime(time))

    if @duration
      progress = 100 * time / 1000 / @duration
      @setProgress progress

  setProgress: (percent) ->
    arrowWidth = Math.floor((percent / 100.0) * (@progressWidth - 3))
    arrowWidth = 1 if arrowWidth < 1

    if arrowWidth != @lastArrowWidth
      arrow = '='.times(arrowWidth) + '>'
      filler = ' '.times(@progressWidth - 3 - arrowWidth)
      @$('.progress').text('[' + arrow + filler + ']')
      @lastArrowWidth = arrowWidth

  formattedTime: (time) ->
    secondsTotal = time / 1000
    minutes = Math.floor(secondsTotal / 60)
    seconds = Math.floor(secondsTotal % 60)
    " #{@pad2(minutes)}:#{@pad2(seconds)} "

  pad2: (number) ->
    if number < 10
      '0' + number
    else
      number

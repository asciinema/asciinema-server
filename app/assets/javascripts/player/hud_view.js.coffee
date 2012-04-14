class AsciiIo.HudView extends Backbone.View
  tagName: 'pre'
  className: 'hud'

  events:
    'click .toggle': 'togglePlay'
    'click .progress span': 'seek'

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

  seek: (e) ->
    index = $(e.target).index()
    percent = 100 * index / (@progressWidth - 2)
    @trigger('hud-seek-click', percent)

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
      bar = arrow + filler
      chars = _(bar.split('')).map (c) -> "<span>#{c}</span>"
      html = chars.join('')
      @$('.progress').html('[' + html + ']')
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

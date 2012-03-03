class AsciiIo.HudView extends Backbone.View
  tagName: 'div'
  className: 'hud'

  events:
    'click .toggle': 'togglePlay'

  initialize: (options) ->
    @duration = undefined
    @createChildViews()

  createChildViews: ->
    toggle   = '<div class="toggle">'
    progress = '<div class="progress"><div class="gutter">'
    time     = '<div class="time">'

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
    @$('.gutter').width("#{percent}%")

  formattedTime: (time) ->
    (time / 1000).toFixed(2)

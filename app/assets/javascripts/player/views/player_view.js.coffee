class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @createRendererView()
    @createHudView() if options.hud
    @showLoadingOverlay()

  createRendererView: ->
    @rendererView = new @options.rendererClass(
      cols:  @options.cols
      lines: @options.lines
    )

    @$el.append @rendererView.$el
    @rendererView.afterInsertedToDom()
    @rendererView.renderSnapshot @options.snapshot

  createHudView: ->
    @hudView = new AsciiIo.HudView(cols: @options.cols)

    @hudView.on 'play-click', => @onPlayClicked()
    @hudView.on 'seek-click', (percent) => @onSeekClicked percent

    @$el.append @hudView.$el

  onModelReady: ->
    @hideLoadingOverlay()
    @hudView.setDuration @model.get('duration') if @hudView

  onStartPromptClick: ->
    @hidePlayOverlay()
    @onPlayClicked()

  onPlayClicked: ->
    @trigger 'play-clicked'

  onSeekClicked: (percent) ->
    @trigger 'seek-clicked', percent

  showLoadingOverlay: ->
    @$el.append('<div class="loading">')

  hideLoadingOverlay: ->
    @$('.loading').remove()

  showPlayOverlay: ->
    @$el.append('<div class="start-prompt"><div class="play-button"><div class="arrow">►</div></div></div>')

  hidePlayOverlay: ->
    @$('.start-prompt').remove()

  onStateChanged: (state) ->
    @$el.removeClass('playing paused')

    switch state
      when 'playing'
        @$el.addClass 'playing'

      when 'finished'
        @rendererView.stopCursorBlink()

      when 'paused'
        @$el.addClass 'paused'
        @hudView.onPause() if @hudView

      when 'resumed'
        @$el.addClass 'playing'
        @hudView.onResume() if @hudView

  renderState: (state) ->
    @rendererView.push state

  updateTime: (time) ->
    @hudView.updateTime time if @hudView

  restartCursorBlink: ->
    @rendererView.restartCursorBlink()

  showCursor: (show) ->
    @rendererView.showCursor show

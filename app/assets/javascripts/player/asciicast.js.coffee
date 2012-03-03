class AsciiIo.Asciicast extends Backbone.Model

  url: ->
    "/asciicasts/#{@get('id')}.json"

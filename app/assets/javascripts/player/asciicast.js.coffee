class AsciiIo.Asciicast extends Backbone.Model

  url: ->
    "/a/#{@get('id')}.json"

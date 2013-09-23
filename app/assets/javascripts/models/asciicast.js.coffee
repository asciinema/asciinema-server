class Asciinema.Asciicast extends Backbone.Model

  url: ->
    "/a/#{@get('id')}.json"

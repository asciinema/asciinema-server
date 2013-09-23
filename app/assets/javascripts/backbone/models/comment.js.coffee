class Asciinema.Models.Comment extends Backbone.Model

  user: ->
    this.get('user')

class Asciinema.Collections.Comments extends Backbone.Collection
  model: Asciinema.Models.Comment

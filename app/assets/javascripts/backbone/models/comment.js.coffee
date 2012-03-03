class AsciiIo.Models.Comment extends Backbone.Model

class AsciiIo.Collections.Comments extends Backbone.Collection
  model: AsciiIo.Models.Comment

  url: '/api/asciicasts/1/comments.json'

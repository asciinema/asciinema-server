class AsciiIo.Views.CommentEntry extends Backbone.View

  template: JST['backbone/templates/comments/show']
  tagName: 'li'
  className: 'comment'

  render: ->
    $(@el).html(@template(@model.toJSON()))

    this

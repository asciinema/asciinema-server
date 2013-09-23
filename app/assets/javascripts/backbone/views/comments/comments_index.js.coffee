class Asciinema.Views.CommentsIndex extends Asciinema.Views.Base

  el: '#comments'

  initialize: ->
    @collection.on('reset', @addAll, this)
    @collection.on('add', @addOne, this)

    $('#new-comment').submit (event) =>
      @createComment(event)

  addAll: ->
    @collection.each (comment) =>
      @addOne(comment)

  addOne:(comment) ->
    view = new Asciinema.Views.CommentEntry({ model: comment, collection: @collection})
    $(this.el).append view.render().el

  createComment: (event) ->
    event.preventDefault()

    attrs = body: $('#comment-body').val()
    @collection.create attrs,
      wait: true
      success: -> $('#new-comment')[0].reset()
      error: @handleError

  handleError: (comment, response) ->
    if response.status == 422
      errors  = $.parseJSON(response.responseText).errors
      for attribute, messages of errors
        alert "#{attribute} #{message}" for message in messages

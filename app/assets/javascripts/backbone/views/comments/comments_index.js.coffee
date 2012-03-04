class AsciiIo.Views.CommentsIndex extends AsciiIo.Views.Base

  el: '#comments'
  template: JST['backbone/templates/comments/index']

  events:
    'submit #new-comment': 'createComment'

  initialize: ->
    @collection.on('reset', @render, this)
    @collection.on('add', @render, this)

  render: ->
    $(@el).html @template( show_form: @current_user )

    $comments = this.$('.comments')

    @collection.each (comment) =>
      view = new AsciiIo.Views.CommentEntry({ model: comment, collection: @collection})
      $comments.append view.render().el

    this

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

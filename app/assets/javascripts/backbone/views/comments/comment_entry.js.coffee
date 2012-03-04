class AsciiIo.Views.CommentEntry extends AsciiIo.Views.Base

  template: JST['backbone/templates/comments/show']
  tagName: 'li'
  className: 'comment'

  events:
    'click .remove': 'removeComment'

  initialize:(options) ->
    @collection = options.collection

  render: ->
    context = _.extend(@model.toJSON(), { show_remove_link: @showRemoveLink() })
    $(@el).html @template(context)
    this

  showRemoveLink: ->
    @current_user() && ( @current_user().id == @model.user().id )

  removeComment: (event) ->
    event.preventDefault()
    @model.destroy
      wait: true
      success: =>
        $(this.el).slideUp("slow", =>
          this.remove()
        )

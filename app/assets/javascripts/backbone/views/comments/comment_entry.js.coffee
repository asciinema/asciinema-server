class AsciiIo.Views.CommentEntry extends AsciiIo.Views.Base

  template: JST['backbone/templates/comments/show']
  tagName: 'li'
  className: 'comment'

  events:
    'click .remove': 'removeComment'

  render: ->
    extra =
      show_remove_link: @showRemoveLink()
      profile_path: "/~#{@model.get('user').nickname}"

    context = _.extend(@model.toJSON(), extra)

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

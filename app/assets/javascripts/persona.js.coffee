$ ->
  $('#persona-button').click (event) ->
    event.preventDefault()
    navigator.id.request { siteName: window.location.hostname }

  if window.browserIdUser
    $('.session-info .logout').click (event) ->
      event.preventDefault()
      navigator.id.logout()

  navigator.id.watch
    loggedInUser: window.browserIdUser

    onlogin: (assertion) ->
      console.log 'onlogin'

      if assertion
        form = $(
          "<form action='/auth/browser_id/callback'>" +
          "<input type='hidden' name='assertion' value='#{assertion}' />"
        )

        $('body').append form
        form.submit()

    onlogout: ->
      console.log 'onlogout'
      window.location = '/logout'

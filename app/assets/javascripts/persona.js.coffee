$ ->
  $('#persona-button, #log-in').click (event) ->
    event.preventDefault()
    navigator.id.request {
      siteName: 'Asciinema',
      siteLogo: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEAAQMAAABmvDolAAAABlBMVEUAAAD///+l2Z/dAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9wHGBMiFVqqanYAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAMklEQVRo3u3KoQEAAAgDoP3/tBaD0WiATAJwVIsgCIIgCIIgCIIgCIIgCIIgCMKHADAafyL3ebnQxskAAAAASUVORK5CYII=',
      backgroundColor: '#06989a',
      privacyPolicy: 'https://asciinema.org/privacy',
      termsOfService: 'https://asciinema.org/tos'
    }

  if window.browserIdUser
    $('header .logout').click (event) ->
      event.preventDefault()
      navigator.id.logout()

  navigator.id.watch
    loggedInUser: window.browserIdUser

    onlogin: (assertion) ->
      if assertion
        form = $(
          "<form action='/auth/browser_id/callback'>" +
          "<input type='hidden' name='assertion' value='#{assertion}' />"
        )

        $('body').append form
        form.submit()

    onlogout: ->
      window.location = '/logout'

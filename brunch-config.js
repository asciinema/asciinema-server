exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js",

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      order: {
        before: [
          "web/static/vendor/js/jquery-2.2.4.min.js",
          "web/static/vendor/js/bootstrap.js"
        ]
      }
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        before: [
          "web/static/vendor/css/bootstrap.css",
          "web/static/css/source-sans-pro.css",
          "web/static/css/base.sass",
          "web/static/css/header.sass",
          "web/static/css/flash.sass",
          "web/static/css/footer.sass",
          "web/static/css/home.sass",
          "web/static/css/asciicasts.sass",
          "web/static/css/users.sass",
          "web/static/css/preview.sass",
          "web/static/css/player.sass",
          "web/static/css/contributing.sass"
        ]
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "web/static",
      "test/static"
    ],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },

  npm: {
    enabled: true
  }
};

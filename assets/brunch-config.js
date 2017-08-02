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
          "vendor/js/jquery-2.2.4.min.js",
          "vendor/js/bootstrap.js"
        ]
      }
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        before: [
          "vendor/css/bootstrap.css",
          "css/source-sans-pro.css",
          "css/base.sass",
          "css/header.sass",
          "css/flash.sass",
          "css/footer.sass",
          "css/home.sass",
          "css/asciicasts.sass",
          "css/users.sass",
          "css/preview.sass",
          "css/player.sass",
          "css/contributing.sass",
          "css/simple-layout.sass",
        ]
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor"],

    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true
  }
};

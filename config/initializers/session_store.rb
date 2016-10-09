# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_asciinema_session', secure: CFG.ssl?
Rails.application.config.action_dispatch.encrypted_cookie_salt = CFG.session_encryption_salt
Rails.application.config.action_dispatch.encrypted_signed_cookie_salt = CFG.session_signing_salt

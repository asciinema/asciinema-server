# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# set secret token from the config object and use a default one for development
AsciiIo::Application.config.secret_token = CFG['SECRET_TOKEN'] || '21deaa1a1228e119434aa783ecb4af21be7513ff1f5b8c1d8894241e5fc70ad395db72c8c1b0508a0ebb994ed88a8d73f6c84e44f7a4bc554a40d77f9844d2f4'

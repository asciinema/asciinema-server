# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
Asciinema::Application.config.secret_key_base = CFG['SECRET_TOKEN'] || '21deaa1a1228e119434aa783ecb4af21be7513ff1f5b8c1d8894241e5fc70ad395db72c8c1b0508a0ebb994ed88a8d73f6c84e44f7a4bc554a40d77f9844d2f4'

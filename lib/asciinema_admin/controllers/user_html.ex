defmodule AsciinemaAdmin.UserHTML do
  use AsciinemaAdmin, :html

  embed_templates "user_html/*"

  @doc """
  Absolute avatar URL for a user. The default-avatar adapter renders a
  relative path on the public endpoint (or a protocol-relative gravatar
  URL); the admin runs on its own origin, so resolve relative paths
  against the public endpoint.
  """
  def avatar_url(user) do
    url = AsciinemaWeb.DefaultAvatar.url(user)

    if String.starts_with?(url, "/") and not String.starts_with?(url, "//") do
      AsciinemaWeb.Endpoint.url() <> url
    else
      url
    end
  end
end

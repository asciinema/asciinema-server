defmodule AsciinemaWeb.PageHTML do
  use AsciinemaWeb, :html

  embed_templates "page_html/*"

  def obfuscated_email(assigns) do
    [username, domain] = String.split(assigns[:address], "@")
    {domain_1, domain_2} = String.split_at(domain, div(String.length(domain), 2))
    assigns = assign(assigns, %{username: username, domain_1: domain_1, domain_2: domain_2})

    ~H"""
    <span class="email">
      <%= @username %>@<%= @domain_1 %><b><%= @domain_2 %></b><%= @domain_2 %>
    </span>
    """
  end
end

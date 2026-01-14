defmodule Asciinema.Repo.Migrations.UpdateCustomFonts do
  use Ecto.Migration

  def change do
    execute "UPDATE users SET term_font_family='Fira Code' WHERE term_font_family='FiraCode Nerd Font'", "UPDATE users SET term_font_family='FiraCode Nerd Font' WHERE term_font_family='Fira Code'"
    execute "UPDATE users SET term_font_family='JetBrains Mono' WHERE term_font_family='JetBrainsMono Nerd Font'", "UPDATE users SET term_font_family='JetBrainsMono Nerd Font' WHERE term_font_family='JetBrains Mono'"
    execute "UPDATE asciicasts SET term_font_family='Fira Code' WHERE term_font_family='FiraCode Nerd Font'", "UPDATE asciicasts SET term_font_family='FiraCode Nerd Font' WHERE term_font_family='Fira Code'"
    execute "UPDATE asciicasts SET term_font_family='JetBrains Mono' WHERE term_font_family='JetBrainsMono Nerd Font'", "UPDATE asciicasts SET term_font_family='JetBrainsMono Nerd Font' WHERE term_font_family='JetBrains Mono'"
  end
end

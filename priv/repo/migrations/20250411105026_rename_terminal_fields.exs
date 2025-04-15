defmodule Asciinema.Repo.Migrations.RenameTerminalFields do
  use Ecto.Migration

  def change do
    rename table(:asciicasts), :terminal_type, to: :term_type
    rename table(:asciicasts), :terminal_line_height, to: :term_line_height
    rename table(:asciicasts), :terminal_font_family, to: :term_font_family
    rename table(:asciicasts), :theme_name, to: :term_theme_name
    rename table(:asciicasts), :theme_fg, to: :term_theme_fg
    rename table(:asciicasts), :theme_bg, to: :term_theme_bg
    rename table(:asciicasts), :theme_palette, to: :term_theme_palette
    rename table(:asciicasts), :cols, to: :term_cols
    rename table(:asciicasts), :cols_override, to: :term_cols_override
    rename table(:asciicasts), :rows, to: :term_rows
    rename table(:asciicasts), :rows_override, to: :term_rows_override

    rename table(:streams), :terminal_line_height, to: :term_line_height
    rename table(:streams), :terminal_font_family, to: :term_font_family
    rename table(:streams), :theme_name, to: :term_theme_name
    rename table(:streams), :theme_prefer_original, to: :term_theme_prefer_original
    rename table(:streams), :theme_fg, to: :term_theme_fg
    rename table(:streams), :theme_bg, to: :term_theme_bg
    rename table(:streams), :theme_palette, to: :term_theme_palette
    rename table(:streams), :cols, to: :term_cols
    rename table(:streams), :rows, to: :term_rows

    rename table(:users), :terminal_font_family, to: :term_font_family
    rename table(:users), :theme_name, to: :term_theme_name
    rename table(:users), :theme_prefer_original, to: :term_theme_prefer_original
  end
end

defmodule Asciinema.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    # users

    create table(:users) do
      add :provider, :string
      add :uid, :string
      add :email, :string
      add :name, :string
      timestamps(inserted_at: :created_at)
      add :username, :string
      add :auth_token, :string
      add :theme_name, :string
      add :temporary_username, :string
      add :asciicasts_private_by_default, :boolean, default: true, null: false
      add :last_login_at, :naive_datetime
    end

    create index(:users, [:auth_token], name: "index_users_on_auth_token")
    create unique_index(:users, [:email], name: "index_users_on_email")
    create unique_index(:users, [:provider, :uid], name: "index_users_on_provider_and_uid")
    create index(:users, [:username], name: "index_users_on_username")

    # api tokens

    create table(:api_tokens) do
      add :user_id, references(:users, name: "api_tokens_user_id_fk"), null: false
      add :token, :string, null: false
      timestamps(inserted_at: :created_at)
      add :revoked_at, :naive_datetime
    end

    create index(:api_tokens, [:token], name: "index_api_tokens_on_token")
    create index(:api_tokens, [:user_id], name: "index_api_tokens_on_user_id")

    # asciicasts

    create table(:asciicasts) do
      add :user_id, references(:users, name: "asciicasts_user_id_fk")
      add :title, :string
      add :duration, :float, null: false
      add :terminal_type, :string
      add :terminal_columns, :integer, null: false
      add :terminal_lines, :integer, null: false
      add :command, :string
      add :shell, :string
      add :uname, :string
      timestamps(inserted_at: :created_at)
      add :stdin_data, :string
      add :stdin_timing, :string
      add :stdout_data, :string
      add :stdout_timing, :string
      add :description, :text
      add :featured, :boolean, default: false
      add :snapshot, :text
      add :time_compression, :boolean, default: true, null: false
      add :views_count, :integer, default: 0, null: false
      add :stdout_frames, :string
      add :user_agent, :string
      add :theme_name, :string
      add :secret_token, :string, null: false
      add :private, :boolean, default: false, null: false
      add :snapshot_at, :float
      add :version, :integer, null: false
      add :file, :string
    end

    create index(:asciicasts, [:created_at], name: "index_asciicasts_on_created_at")
    create index(:asciicasts, [:featured], name: "index_asciicasts_on_featured")
    create index(:asciicasts, [:private], name: "index_asciicasts_on_private")
    create unique_index(:asciicasts, [:secret_token], name: "index_asciicasts_on_secret_token")
    create index(:asciicasts, [:user_id], name: "index_asciicasts_on_user_id")
    create index(:asciicasts, [:views_count], name: "index_asciicasts_on_views_count")
  end
end

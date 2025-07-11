defmodule Asciinema.Repo.Migrations.FixNamingInconsistencies do
  use Ecto.Migration

  def up do
    # Fix sequence names
    execute "ALTER SEQUENCE api_tokens_id_seq RENAME TO clis_id_seq"
    execute "ALTER SEQUENCE live_streams_id_seq RENAME TO streams_id_seq"

    # Fix streams table indices
    execute "ALTER INDEX live_streams_pkey RENAME TO streams_pkey"
    execute "ALTER INDEX live_streams_current_viewer_count_index RENAME TO streams_current_viewer_count_index"
    execute "ALTER INDEX live_streams_inserted_at_index RENAME TO streams_inserted_at_index"
    execute "ALTER INDEX live_streams_last_started_at_index RENAME TO streams_last_started_at_index"
    execute "ALTER INDEX live_streams_online_index RENAME TO streams_online_index"
    execute "ALTER INDEX live_streams_parser_index RENAME TO streams_parser_index"
    execute "ALTER INDEX live_streams_peak_viewer_count_index RENAME TO streams_peak_viewer_count_index"
    execute "ALTER INDEX live_streams_producer_token_index RENAME TO streams_producer_token_index"
    execute "ALTER INDEX live_streams_secret_token_index RENAME TO streams_secret_token_index"
    execute "ALTER INDEX live_streams_user_id_index RENAME TO streams_user_id_index"
    execute "ALTER INDEX live_streams_user_id_secret_token_index RENAME TO streams_user_id_secret_token_index"

    # Fix users table indices
    execute "ALTER INDEX index_users_on_auth_token RENAME TO users_auth_token_index"
    execute "ALTER INDEX index_users_on_email RENAME TO users_email_index"
    execute "ALTER INDEX index_users_on_provider_and_uid RENAME TO users_provider_uid_index"
    execute "ALTER INDEX index_users_on_username RENAME TO users_username_unique_index"
    execute "DROP INDEX users_username_index"  # Remove duplicate index

    # Fix constraint names
    execute "ALTER TABLE clis RENAME CONSTRAINT api_tokens_user_id_fk TO clis_user_id_fkey"
    execute "ALTER TABLE streams RENAME CONSTRAINT live_streams_user_id_fkey TO streams_user_id_fkey"
  end

  def down do
    # Revert constraint names
    execute "ALTER TABLE streams RENAME CONSTRAINT streams_user_id_fkey TO live_streams_user_id_fkey"
    execute "ALTER TABLE clis RENAME CONSTRAINT clis_user_id_fkey TO api_tokens_user_id_fk"

    # Revert users table indices
    execute "CREATE INDEX users_username_index ON users USING btree (username)"  # Recreate duplicate index
    execute "ALTER INDEX users_username_unique_index RENAME TO index_users_on_username"
    execute "ALTER INDEX users_provider_uid_index RENAME TO index_users_on_provider_and_uid"
    execute "ALTER INDEX users_email_index RENAME TO index_users_on_email"
    execute "ALTER INDEX users_auth_token_index RENAME TO index_users_on_auth_token"

    # Revert streams table indices
    execute "ALTER INDEX streams_user_id_secret_token_index RENAME TO live_streams_user_id_secret_token_index"
    execute "ALTER INDEX streams_user_id_index RENAME TO live_streams_user_id_index"
    execute "ALTER INDEX streams_secret_token_index RENAME TO live_streams_secret_token_index"
    execute "ALTER INDEX streams_producer_token_index RENAME TO live_streams_producer_token_index"
    execute "ALTER INDEX streams_peak_viewer_count_index RENAME TO live_streams_peak_viewer_count_index"
    execute "ALTER INDEX streams_parser_index RENAME TO live_streams_parser_index"
    execute "ALTER INDEX streams_online_index RENAME TO live_streams_online_index"
    execute "ALTER INDEX streams_last_started_at_index RENAME TO live_streams_last_started_at_index"
    execute "ALTER INDEX streams_inserted_at_index RENAME TO live_streams_inserted_at_index"
    execute "ALTER INDEX streams_current_viewer_count_index RENAME TO live_streams_current_viewer_count_index"
    execute "ALTER INDEX streams_pkey RENAME TO live_streams_pkey"

    # Revert sequence names
    execute "ALTER SEQUENCE streams_id_seq RENAME TO live_streams_id_seq"
    execute "ALTER SEQUENCE clis_id_seq RENAME TO api_tokens_id_seq"
  end
end

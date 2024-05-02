defmodule Asciinema.Repo.Migrations.LowercaseEmails do
  use Ecto.Migration

  @get_dup_emails "SELECT LOWER(email) AS e FROM users WHERE email IS NOT NULL GROUP BY e HAVING COUNT(*) > 1"
  @get_users_for_email "SELECT u.id, COUNT(a.id) AS asciicast_count FROM users u LEFT OUTER JOIN asciicasts a ON (a.user_id = u.id) WHERE LOWER(u.email) = $1 GROUP BY u.id ORDER BY asciicast_count DESC, name, username"
  @update_email "UPDATE users SET email = CONCAT('_', $2::int, '_', email) WHERE id = $1"

  def change do
    execute(fn ->
      for [email] <- repo().query!(@get_dup_emails).rows do
        for {[id | _], i}  <- Enum.with_index(repo().query!(@get_users_for_email, [email]).rows) do
          if i > 0 do
            repo().query!(@update_email, [id, i])
          end
        end
      end
    end, fn -> :ok end)

    execute "UPDATE users SET email=LOWER(email) WHERE email IS NOT NULL", ""
  end
end

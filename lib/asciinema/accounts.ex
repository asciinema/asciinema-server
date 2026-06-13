defmodule Asciinema.Accounts do
  use Asciinema.Config
  import Ecto.Query, warn: false
  import Ecto, only: [assoc: 2, build_assoc: 2]
  alias Asciinema.Accounts.{Cli, Query, User}
  alias Asciinema.{Fonts, Repo, Themes}
  alias Ecto.Changeset
  alias Phoenix.Token

  @valid_email_re ~r/^[A-Z0-9._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,}$/i
  @valid_username_re ~r/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/
  @email_hash_bytes 8

  def get_user([{_k, _v}] = kv), do: Repo.get_by(User, kv)

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def fetch_user(id), do: OK.required(get_user(id), :not_found)

  def find_user(%User{} = user), do: user

  def find_user(id) when is_integer(id), do: get_user(id)

  def find_user(id) when is_binary(id) do
    {_, user} = lookup_user(id)

    user
  end

  def find_user_by_username(username) do
    Repo.one(
      from(u in User,
        where: fragment("lower(?)", u.username) == ^String.downcase(username)
      )
    )
  end

  def find_user_by_profile_id("user:" <> id) do
    case Integer.parse(id) do
      {id, ""} ->
        # narrowing to users with NULL username limits enumeration attacks
        Repo.one(from(u in User, where: u.id == ^id and is_nil(u.username)))

      _ ->
        nil
    end
  end

  def find_user_by_profile_id(username) when is_binary(username) do
    find_user_by_username(username)
  end

  def find_user_by_auth_token(auth_token) do
    Repo.get_by(User, auth_token: auth_token)
  end

  def query(%Query{} = spec) do
    from(u in User, as: :user)
    |> apply_scope(spec.scope)
    |> apply_filters(spec.filters)
    |> sort(spec.sort)
  end

  defp apply_scope(query, :admin), do: query
  defp apply_scope(query, :system), do: query

  defp apply_filters(q, filters) when is_list(filters) do
    filters
    |> Enum.uniq()
    |> Enum.reduce(q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, id} ->
        where(q, [u], u.id == ^id)

      {:identity, {:search, text}} ->
        search_identity(q, text)

      {:username, {:search, text}} ->
        where(q, [u], ilike(u.username, ^"%#{escape_like(text)}%"))

      {:email, {:search, text}} ->
        where(q, [u], ilike(u.email, ^"%#{escape_like(text)}%"))

      {:name, {:search, text}} ->
        where(q, [u], ilike(u.name, ^"%#{escape_like(text)}%"))

      {:admin, bool} ->
        where(q, [u], u.is_admin == ^bool)

      # A user is "registered" once they have an account email; temporary users have none.
      {:registered, true} ->
        where(q, [u], not is_nil(u.email))

      {:registered, false} ->
        where(q, [u], is_nil(u.email))

      {:created_at, condition} ->
        apply_field_condition(q, :inserted_at, condition)

      {:last_login_at, condition} ->
        apply_field_condition(q, :last_login_at, condition)

      {:recording_count, condition} ->
        q
        |> with_counts()
        |> apply_count_condition(:recording_count, condition)

      {:stream_count, condition} ->
        q
        |> with_counts()
        |> apply_count_condition(:stream_count, condition)
    end
  end

  defp search_identity(q, text) do
    text
    |> String.split()
    |> Enum.reduce(q, fn term, q ->
      pattern = "%#{escape_like(term)}%"

      where(
        q,
        [u],
        ilike(u.username, ^pattern) or ilike(u.email, ^pattern) or ilike(u.name, ^pattern)
      )
    end)
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  defp apply_field_condition(q, field, {:gt, value}), do: where(q, [u], field(u, ^field) > ^value)

  defp apply_field_condition(q, field, {:gte, value}),
    do: where(q, [u], field(u, ^field) >= ^value)

  defp apply_field_condition(q, field, {:lt, value}), do: where(q, [u], field(u, ^field) < ^value)

  defp apply_field_condition(q, field, {:lte, value}),
    do: where(q, [u], field(u, ^field) <= ^value)

  defp apply_field_condition(q, field, {:between, from_value, to_value}),
    do: where(q, [u], field(u, ^field) >= ^from_value and field(u, ^field) <= ^to_value)

  defp apply_count_condition(q, :recording_count, condition) do
    apply_count_condition(q, :recording_counts, condition)
  end

  defp apply_count_condition(q, :stream_count, condition) do
    apply_count_condition(q, :stream_counts, condition)
  end

  defp apply_count_condition(q, binding, {:eq, value}),
    do: where(q, [{^binding, c}], coalesce(c.count, 0) == ^value)

  defp apply_count_condition(q, binding, {:gt, value}),
    do: where(q, [{^binding, c}], coalesce(c.count, 0) > ^value)

  defp apply_count_condition(q, binding, {:gte, value}),
    do: where(q, [{^binding, c}], coalesce(c.count, 0) >= ^value)

  defp apply_count_condition(q, binding, {:lt, value}),
    do: where(q, [{^binding, c}], coalesce(c.count, 0) < ^value)

  defp apply_count_condition(q, binding, {:lte, value}),
    do: where(q, [{^binding, c}], coalesce(c.count, 0) <= ^value)

  defp apply_count_condition(q, binding, {:between, from_value, to_value}) do
    where(
      q,
      [{^binding, c}],
      coalesce(c.count, 0) >= ^from_value and coalesce(c.count, 0) <= ^to_value
    )
  end

  defp sort(q, nil), do: q
  defp sort(q, {:created, :desc}), do: order_by(q, [u], desc: u.inserted_at, desc: u.id)
  defp sort(q, {:created, :asc}), do: order_by(q, [u], asc: u.inserted_at, asc: u.id)

  defp sort(q, {:last_login, :desc}),
    do: order_by(q, [u], desc_nulls_last: u.last_login_at, desc: u.id)

  defp sort(q, {:last_login, :asc}),
    do: order_by(q, [u], asc_nulls_last: u.last_login_at, asc: u.id)

  defp sort(q, {:recordings, dir}) when dir in [:asc, :desc] do
    q
    |> with_counts()
    |> order_by([u, recording_counts: c], [{^dir, coalesce(c.count, 0)}, {^dir, u.id}])
  end

  defp sort(q, {:streams, dir}) when dir in [:asc, :desc] do
    q
    |> with_counts()
    |> order_by([u, stream_counts: c], [{^dir, coalesce(c.count, 0)}, {^dir, u.id}])
  end

  def paginate(%Query{} = spec, page, page_size, opts \\ []) do
    spec
    |> query()
    |> maybe_with_counts(Keyword.get(opts, :with_counts, false))
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def list(%Query{} = spec, limit, opts \\ []) do
    spec
    |> query()
    |> maybe_with_counts(Keyword.get(opts, :with_counts, false))
    |> limit(^limit)
    |> Repo.all()
  end

  def count(%Query{} = spec), do: spec |> query() |> count()
  def count(q), do: Repo.count(q)

  @doc "List of `{Date, count}` of new users per day over the last `days` days, oldest first."
  def signups_by_day(days) when is_integer(days) and days > 0 do
    today = Date.utc_today()
    start_date = Date.add(today, -(days - 1))
    cutoff = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    rows =
      from(u in User,
        where: u.inserted_at >= ^cutoff,
        group_by: fragment("date_trunc('day', ?)::date", u.inserted_at),
        select: {fragment("date_trunc('day', ?)::date", u.inserted_at), count()}
      )
      |> Repo.all()
      |> Map.new()

    start_date
    |> Date.range(today)
    |> Enum.map(fn d -> {d, Map.get(rows, d, 0)} end)
  end

  # When a count filter/sort already forced the aggregate joins, reuse them;
  # otherwise correlated subqueries count only the rows on the returned page.
  defp maybe_with_counts(q, true) do
    if has_named_binding?(q, :recording_counts) or has_named_binding?(q, :stream_counts) do
      with_counts(q)
    else
      select_merge(q, %{
        recording_count: subquery(count_for_user(Asciinema.Recordings.Asciicast)),
        stream_count: subquery(count_for_user(Asciinema.Streaming.Stream))
      })
    end
  end

  defp maybe_with_counts(q, false), do: q

  defp count_for_user(schema) do
    from(r in schema, where: r.user_id == parent_as(:user).id, select: count())
  end

  defp with_counts(q) do
    q
    |> ensure_recording_counts_join()
    |> ensure_stream_counts_join()
    |> select_merge([recording_counts: rc, stream_counts: sc], %{
      recording_count: coalesce(rc.count, 0),
      stream_count: coalesce(sc.count, 0)
    })
  end

  defp ensure_recording_counts_join(q) do
    if has_named_binding?(q, :recording_counts) do
      q
    else
      counts =
        from(a in Asciinema.Recordings.Asciicast,
          group_by: a.user_id,
          select: %{user_id: a.user_id, count: count(a.id)}
        )

      join(q, :left, [u], c in subquery(counts), on: c.user_id == u.id, as: :recording_counts)
    end
  end

  defp ensure_stream_counts_join(q) do
    if has_named_binding?(q, :stream_counts) do
      q
    else
      counts =
        from(s in Asciinema.Streaming.Stream,
          group_by: s.user_id,
          select: %{user_id: s.user_id, count: count(s.id)}
        )

      join(q, :left, [u], c in subquery(counts), on: c.user_id == u.id, as: :stream_counts)
    end
  end

  def build_user(attrs \\ %{}) do
    Changeset.change(
      %User{
        default_recording_visibility: config(:default_recording_visibility, :unlisted),
        default_stream_visibility: config(:default_stream_visibility, :unlisted),
        streaming_enabled: config(:default_streaming_enabled, true),
        live_stream_limit: config(:default_live_stream_limit, nil)
      },
      attrs
    )
  end

  def create_user(attrs) do
    import Ecto.Changeset

    build_user()
    |> cast(attrs, [:email, :username])
    |> validate_required([:email, :username])
    |> validate_email()
    |> validate_username()
    |> add_contraints()
    |> Repo.insert()
  end

  def ensure_asciinema_user do
    case Repo.get_by(User, username: "asciinema") do
      nil ->
        attrs = %{
          username: "asciinema",
          name: "asciinema",
          email: "admin@asciinema.org"
        }

        attrs
        |> build_user()
        |> Repo.insert!()

      user ->
        user
    end
  end

  def change_user(user, params \\ %{}, ctx \\ :user)

  def change_user(user, params, :user) do
    import Ecto.Changeset

    user
    |> cast(params, [
      :name,
      :username,
      :timezone,
      :term_theme_name,
      :term_theme_prefer_original,
      :term_bold_is_bright,
      :term_adaptive_palette,
      :term_font_family,
      :default_recording_visibility,
      :default_stream_visibility,
      :stream_recording_enabled
    ])
    |> validate_required([:username])
    |> validate_username()
    |> validate_inclusion(:timezone, Tzdata.canonical_zone_list())
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes())
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> add_contraints()
  end

  def change_user(user, params, :admin) do
    import Ecto.Changeset

    user
    |> cast(params, [
      :email,
      :name,
      :username,
      :is_admin,
      :streaming_enabled,
      :live_stream_limit
    ])
    |> validate_required([:email, :username])
    |> validate_email()
    |> validate_username()
    |> validate_number(:live_stream_limit, greater_than_or_equal_to: 0)
    |> add_contraints()
  end

  defp validate_email(changeset) do
    import Ecto.Changeset

    changeset
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @valid_email_re)
  end

  defp validate_username(changeset) do
    import Ecto.Changeset

    changeset
    |> validate_format(:username, @valid_username_re)
    |> validate_length(:username, min: 2, max: 16)
  end

  defp add_contraints(changeset) do
    import Ecto.Changeset

    changeset
    |> unique_constraint(:username, name: "users_username_unique_index")
    |> unique_constraint(:email, name: "users_email_index")
  end

  def update_user(user, params, ctx \\ :user) do
    user
    |> change_user(params, ctx)
    |> Repo.update()
  end

  def cli_registered?(%Cli{} = cli), do: cli.user.email != nil

  def temporary_users(q \\ User) do
    from(u in q, where: is_nil(u.email))
  end

  def sign_up_enabled?, do: config(:sign_up_enabled?, true)

  def initiate_login(identifier, opts \\ []) do
    sign_up_enabled? = Keyword.get(opts, :register, sign_up_enabled?())

    case {lookup_user(identifier), sign_up_enabled?} do
      {{_, %User{email: nil}}, _} ->
        {:error, :email_missing}

      {{_, %User{} = user}, _} ->
        {:ok, {:login, generate_login_token(user), user.email}}

      {{:email, nil}, true} ->
        changeset =
          %User{}
          |> Changeset.change(%{email: identifier})
          |> validate_email()

        if Enum.any?(changeset.errors, &(elem(&1, 0) == :email)) do
          {:error, :email_invalid}
        else
          email = changeset.changes.email

          {:ok, {:sign_up, generate_sign_up_token(email), email}}
        end

      {{_, nil}, _} ->
        {:error, :user_not_found}
    end
  end

  def lookup_user(identifier) when is_binary(identifier) do
    if String.contains?(identifier, "@") do
      {:email, Repo.get_by(User, email: String.downcase(identifier))}
    else
      {:username, find_user_by_username(identifier)}
    end
  end

  def generate_sign_up_token(email) do
    Token.sign(config(:secret), "sign_up", email)
  end

  def generate_login_token(%User{id: id, last_login_at: last_login_at}) do
    last_login_at = last_login_at && Timex.to_unix(last_login_at)
    Token.sign(config(:secret), "login", {id, last_login_at})
  end

  def confirm_sign_up(token, username, timezone \\ nil) do
    with {:ok, email} <- verify_sign_up_token(token),
         {:ok, user} <- create_user(%{email: email, username: username}) do
      {:ok, set_timezone(user, timezone)}
    else
      {:error, :invalid} -> {:error, :token_invalid}
      {:error, %Ecto.Changeset{errors: [{:email, _}]}} -> {:error, :email_taken}
      {:error, %Ecto.Changeset{errors: [{:username, _} | _]} = changeset} -> {:error, changeset}
      {:error, _} -> {:error, :token_expired}
    end
  end

  def verify_sign_up_token(token) do
    Token.verify(config(:secret), "sign_up", token,
      max_age: config(:login_token_max_age, 60) * 60
    )
  end

  def confirm_login(token, timezone \\ nil) do
    with {:ok, {user_id, last_login_at}} <- verify_login_token(token),
         %User{} = user <- Repo.get(User, user_id),
         ^last_login_at <- user.last_login_at && Timex.to_unix(user.last_login_at) do
      {:ok, set_timezone(user, timezone)}
    else
      {:error, :invalid} ->
        {:error, :token_invalid}

      nil ->
        {:error, :user_not_found}

      _ ->
        {:error, :token_expired}
    end
  end

  defp set_timezone(%User{timezone: nil} = user, timezone) do
    import Ecto.Changeset

    changeset =
      user
      |> cast(%{timezone: timezone}, [:timezone])
      |> validate_inclusion(:timezone, Tzdata.canonical_zone_list())

    case Repo.update(changeset) do
      {:ok, user} -> user
      {:error, _} -> user
    end
  end

  defp set_timezone(user, _timezone), do: user

  def verify_login_token(token) do
    Token.verify(config(:secret), "login", token, max_age: config(:login_token_max_age, 60) * 60)
  end

  def initiate_email_change(user, email) do
    import Ecto.Changeset

    changeset =
      user
      |> cast(%{email: email}, [:email])
      |> validate_required([:email])
      |> validate_email()
      |> add_contraints()

    if changeset.changes == %{} do
      {:ok, :changed}
    else
      {:error, result} =
        Repo.transact(fn ->
          case Repo.update(changeset) do
            {:ok, updated_user} ->
              token = generate_email_change_token(user, updated_user.email)

              {:error, {:ok, {:pending, {updated_user.email, token}}}}

            {:error, %Changeset{errors: [{:email, {_, [{:validation, :format}]}}]}} ->
              {:error, {:error, :invalid}}

            {:error, %Changeset{errors: [{:email, {_, [{:constraint, :unique} | _]}}]}} ->
              {:error, {:error, :taken}}
          end
        end)

      result
    end
  end

  def generate_email_change_token(user, email) do
    Token.sign(config(:secret), "email-change", {user.id, email_hash(user.email), email})
  end

  def verify_email_change(user, token), do: do_verify_email_change(user, token)

  def confirm_email_change(user, token) do
    case do_verify_email_change(user, token) do
      {:ok, email} ->
        result =
          user
          |> Changeset.change(email: email)
          |> add_contraints()
          |> Repo.update()

        case result do
          {:ok, user} -> {:ok, user}
          _ -> {:error, :email_taken}
        end

      {:error, _reason} = result ->
        result
    end
  end

  defp do_verify_email_change(user, token) do
    case Token.verify(config(:secret), "email-change", token, max_age: 3600) do
      {:ok, {user_id, old_email_hash, email}} ->
        cond do
          user.id != user_id -> {:error, :user_mismatch}
          email_hash(user.email) != old_email_hash -> {:error, :email_changed}
          true -> {:ok, email}
        end

      {:error, _} ->
        {:error, :invalid_token}
    end
  end

  defp email_hash(email) do
    :sha256
    |> :crypto.hash(String.downcase(email))
    |> binary_part(0, @email_hash_bytes)
  end

  def initiate_account_deletion(user), do: generate_deletion_token(user)

  def generate_deletion_token(%User{id: user_id}) do
    Token.sign(config(:secret), "acct-delete", user_id)
  end

  def confirm_account_deletion(token) do
    with {:ok, user_id} <- verify_deletion_token(token),
         %User{} = user <- Repo.get(User, user_id) do
      {:ok, user}
    else
      _ -> {:error, :token_invalid}
    end
  end

  def verify_deletion_token(token) do
    Token.verify(config(:secret), "acct-delete", token, max_age: 3600)
  end

  @uuid4 ~r/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/

  def preview_cli_claim(%User{} = user, install_id) do
    case fetch_cli(install_id) do
      {:ok, cli} ->
        preview_cli_ownership(user, cli)

      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} ->
        if valid_install_id?(install_id) do
          {:ok, :new_cli}
        else
          {:error, :token_invalid}
        end
    end
  end

  def claim_cli(%User{} = user, install_id) do
    case fetch_cli(install_id) do
      {:ok, cli} ->
        check_cli_ownership(user, cli)

      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} ->
        create_cli(user, install_id)
    end
  end

  def get_or_create_upload_cli(username, install_id) when is_binary(username) do
    case fetch_cli(install_id) do
      {:ok, cli} ->
        {:ok, cli}

      {:error, :cli_revoked} = result ->
        result

      {:error, :token_not_found} = result ->
        if config(:upload_auth_required, false) do
          result
        else
          create_cli(create_tmp_user(username), install_id)
        end
    end
  end

  defp create_cli(%User{} = user, install_id) do
    result =
      user
      |> new_cli(%{token: install_id})
      |> Repo.insert()

    case result do
      {:ok, cli} ->
        {:ok, %{cli | user: user}}

      {:error, %Ecto.Changeset{}} ->
        {:error, :token_invalid}
    end
  end

  def new_cli(user, attrs \\ %{}) do
    import Changeset

    user
    |> build_assoc(:clis)
    |> cast(attrs, [:token])
    |> validate_required([:token])
    |> validate_format(:token, @uuid4)
    |> unique_constraint(:token, name: "clis_token_index")
  end

  defp create_tmp_user(username) do
    %{temporary_username: String.slice(username, 0, 16)}
    |> build_user()
    |> Repo.insert!()
  end

  defp check_cli_ownership(user, cli) do
    cond do
      user.id == cli.user.id -> {:ok, cli}
      cli.user.email -> {:error, :token_taken}
      true -> {:error, {:needs_merge, cli.user}}
    end
  end

  defp preview_cli_ownership(user, cli) do
    cond do
      user.id == cli.user.id -> {:ok, :owned_by_user}
      cli.user.email -> {:error, :token_taken}
      true -> {:ok, {:claimable_tmp_user, cli, Repo.count(assoc(cli.user, :asciicasts))}}
    end
  end

  defp valid_install_id?(install_id) do
    Regex.match?(@uuid4, install_id)
  end

  def fetch_cli(token) do
    cli =
      Cli
      |> Repo.get_by(token: token)
      |> Repo.preload(:user)

    case cli do
      nil -> {:error, :token_not_found}
      %Cli{revoked_at: nil} -> {:ok, cli}
      %Cli{} -> {:error, :cli_revoked}
    end
  end

  def get_cli(user, id) do
    Repo.get(assoc(user, :clis), id)
  end

  def get_cli!(token) do
    Repo.get_by!(Cli, token: token)
  end

  def revoke_cli!(%Cli{revoked_at: nil} = cli) do
    cli
    |> Changeset.change(%{revoked_at: DateTime.utc_now(:second)})
    |> Repo.update!()
  end

  def revoke_cli!(cli), do: cli

  def list_clis(%User{} = user) do
    user
    |> assoc(:clis)
    |> Repo.all()
  end

  def reassign_clis(src_user_id, dst_user_id) do
    q = from(at in Cli, where: at.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def regenerate_auth_token(user) do
    user
    |> Changeset.change(%{auth_token: Crypto.random_token(20)})
    |> Repo.update!()
  end

  def update_last_login(user) do
    user
    |> Changeset.change(%{last_login_at: DateTime.utc_now(:second)})
    |> Repo.update!()
  end

  def add_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: true])
  end

  def remove_admins(emails) do
    from(u in User, where: u.email in ^emails)
    |> Repo.update_all(set: [is_admin: false])
  end

  def delete_user!(%User{} = user) do
    Repo.delete_all(assoc(user, :clis))
    Repo.delete!(user)

    :ok
  end

  def default_term_theme_name(user), do: user.term_theme_name || Themes.default_name()

  def default_font_family(user), do: user.term_font_family
end

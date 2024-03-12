defmodule AsciinemaWeb.CoreComponents do
  use Phoenix.Component
  import AsciinemaWeb.ErrorHelpers

  attr :for, Phoenix.HTML.FormField
  attr :rest, :global
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for.id} {@rest}><%= render_slot(@inner_block) %></label>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file hidden month number password range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :rest, :global,
    include:
      ~w(autocomplete cols disabled form max maxlength min minlength pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input type="checkbox" id={@id || @name} name={@name} value="true" checked={@checked} {@rest} />
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select id={@id} name={@name} {@rest}>
      <option :if={@prompt} value=""><%= @prompt %></option>
      <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
    </select>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea id={@id || @name} name={@name} {@rest}><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id || @name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      {@rest}
    />
    """
  end

  attr :type, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} {@rest}><%= render_slot(@inner_block) %></button>
    """
  end

  attr :time, :any, required: true
  attr :rest, :global

  def time_ago(assigns) do
    ~H"""
    <time
      datetime={Timex.format!(@time, "{ISO:Extended:Z}")}
      title={Timex.format!(@time, "{RFC1123z}")}
      {@rest}
    >
      <%= Timex.from_now(@time) %>
    </time>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true

  def error(assigns) do
    assigns = assign(assigns, :error, List.first(assigns.field.errors))

    ~H"""
    <small :if={@error} class="form-text text-danger"><%= translate_error(@error) %></small>
    """
  end
end

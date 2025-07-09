defmodule TestAppWeb.UserLive.FormComponent do
  use TestAppWeb, :live_component

  alias TestApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan Borang ini untuk mengelola data pengguna di database Anda.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:age]} type="number" label="Age" phx-change="update_category" />
        <.input field={@form[:gender]} type="select" label="Gender" options={[{"Male", "male"}, {"Female", "female"}]} />
        <.input field={@form[:category]} type="text" label="Category" readonly />
        <:actions>
          <.button phx-disable-with="Menyimpan  ...">Simpan</.button>
        </:actions>
      </.simple_form>

      <script>
        document.addEventListener('phx:update', function() {
          const ageInput = document.querySelector('input[name="user[age]"]');
          const categoryInput = document.querySelector('input[name="user[category]"]');

          if (ageInput && categoryInput) {
            ageInput.addEventListener('input', function() {
              const age = parseInt(this.value);
              let category = '';

              if (age >= 1 && age <= 12) {
                category = 'Child';
              } else if (age >= 13 && age <= 19) {
                category = 'Teen';
              } else if (age >= 20 && age <= 64) {
                category = 'Adult';
              } else if (age >= 65) {
                category = 'Senior';
              }

              categoryInput.value = category;
            });
          }
        });
      </script>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("update_category", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

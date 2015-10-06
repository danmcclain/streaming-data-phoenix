defmodule StreamingData.ContactsChannel do
  use Phoenix.Channel
  alias StreamingData.Contact
  alias StreamingData.Repo

  def join("contacts:index", auth_msg, socket) do
    {:ok, socket}
  end

  def handle_in("all", payload, socket) do
    contacts = Repo.all(Contact)

    payload = StreamingData.ContactSerializer.format(contacts)

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("create", %{"data" => %{"attributes" => attributes, "type" => "contacts"}}, socket) do
    contact = %Contact{}
    |> Contact.changeset(normalize_attributes(attributes))
    |> Repo.insert!

    payload = StreamingData.ContactSerializer.format(contact)
    broadcast! socket, "new_contact", payload

    {:reply, {:ok, payload}, socket}
  end

  defp normalize_attributes(attributes) do
    attributes
    |> Enum.map(fn {key, value} -> {String.replace(key, "-", "_"), value} end)
    |> Enum.into(%{})
  end
end

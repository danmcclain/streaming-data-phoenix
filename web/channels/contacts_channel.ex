defmodule StreamingData.ContactsChannel do
  use Phoenix.Channel
  alias StreamingData.Contact
  alias StreamingData.Repo

  def join("contacts:" <> _scoped_id, auth_msg, socket) do
    IO.inspect _scoped_id
    {:ok, socket}
  end

  def handle_in("all", payload, socket) do
    IO.inspect payload
    contacts = Repo.all(Contact)

    payload = StreamingData.ContactSerializer.format(contacts)
    # payload = payload
    # |> Map.put(:meta, %{since: 3})

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("find", id, socket) do
    contact = Repo.get(Contact, id)

    payload = StreamingData.ContactSerializer.format(contact)

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("update", %{"data" => %{"id" => id, "attributes" => attributes, "type" => "contacts"}}, socket) do
    contact = Repo.get(Contact, id)
    |> Contact.changeset(normalize_attributes(attributes))
    |> StreamingData.StreamingRepo.update!([from: socket])

    payload = StreamingData.ContactSerializer.format(contact)

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("create", %{"data" => %{"attributes" => attributes, "type" => "contacts"}}, socket) do
    {:ok, contact} = StreamingData.StreamingRepo.transaction fn ->
      %Contact{}
      |> Contact.changeset(normalize_attributes(attributes))
      |> StreamingData.StreamingRepo.insert!([from: socket])

      StreamingData.StreamingRepo.insert!(nil)
    end

    payload = StreamingData.ContactSerializer.format(contact)

    {:reply, {:ok, payload}, socket}
  end

  defp normalize_attributes(attributes) do
    attributes
    |> Enum.map(fn {key, value} -> {String.replace(key, "-", "_"), value} end)
    |> Enum.into(%{})
  end
end


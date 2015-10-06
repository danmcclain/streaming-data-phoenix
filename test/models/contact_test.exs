defmodule StreamingData.ContactTest do
  use StreamingData.ModelCase

  alias StreamingData.Contact

  @valid_attrs %{first_name: "some content", last_name: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contact.changeset(%Contact{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contact.changeset(%Contact{}, @invalid_attrs)
    refute changeset.valid?
  end
end

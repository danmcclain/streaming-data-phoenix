defmodule StreamingData.Contact do
  # use EmberChannel.Model
  def channel_name do
    __schema__(:source)
  end

  def channel_scope(_model) do
    "index"
  end

  use StreamingData.Web, :model

  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    field :title, :string

    timestamps
  end

  @required_fields ~w(first_name)
  @optional_fields ~w(last_name title)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

defmodule StreamingData.StreamingRepo do
  @repo StreamingData.Repo
  @endpoint StreamingData.Endpoint

  def insert!(model, options \\ []) do
    if from = Dict.get(options, :from) do
      Dict.delete(options, :from)
    end
    model = @repo.insert!(model, options)

    payload = StreamingData.ContactSerializer.format(model)
    if from do
      %{channel_pid: channel_pid} = from
      @endpoint.broadcast_from channel_pid, "contacts:index", "new", payload
    else
      @endpoint.broadcast "contacts:index", "new", payload
    end
    model
  end

  def update!(model, options \\ []) do
    if from = Dict.get(options, :from) do
      Dict.delete(options, :from)
    end
    model = @repo.update!(model, options)

    payload = StreamingData.ContactSerializer.format(model)
    if from do
      %{channel_pid: channel_pid} = from
      @endpoint.broadcast_from channel_pid, "contacts:index", "new", payload
    else
      @endpoint.broadcast "contacts:index", "update", payload
    end
    model
  end
end

defmodule StreamingData.StreamingRepo do
  @repo StreamingData.Repo
  @endpoint StreamingData.Endpoint

  def insert!(model, options \\ []) do
    brodcast_action!(&@repo.insert!/2, model, options, "new")
  end

  def update!(model, options \\ []) do
    brodcast_action!(&@repo.update!/2, model, options, "update")
  end

  defp brodcast_action!(action_func, model, options, event) do
    if from = Dict.get(options, :from) do
      Dict.delete(options, :from)
    end
    model = action_func.(model, options)

    channel = "contacts:index"

    payload = StreamingData.ContactSerializer.format(model)

    if from do
      %{channel_pid: channel_pid} = from
      @endpoint.broadcast_from channel_pid, channel, event, payload
    else
      @endpoint.broadcast channel, event, payload
    end

    model
  end
end

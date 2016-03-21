defmodule StreamingData.StreamingRepo do
  @repo StreamingData.Repo
  @endpoint StreamingData.Endpoint

  def insert!(model, options \\ []) do
    brodcast_action(&@repo.insert!/2, model, options, "new")
  end

  def insert(model, options \\ []) do
    brodcast_action(&@repo.insert/2, model, options, "new")
  end

  def update!(model, options \\ []) do
    brodcast_action(&@repo.update!/2, model, options, "update")
  end

  def update(model, options \\ []) do
    brodcast_action(&@repo.update/2, model, options, "update")
  end

  def transaction(func, opts \\ []) do
    {from, opts} = Keyword.pop(opts, :from)

    queue = if not @repo.in_transaction? do
      {:ok, pid} = EmberChannel.BroadcastQueue.spawn(@endpoint, [from: from])
      Process.put(:ember_channel_queue, pid)
      pid
    end

    result = @repo.transaction(func)

    if queue do
      case result do
        {:ok, _result} -> EmberChannel.BroadcastQueue.flush(queue)
      end

      # Stop queue
      EmberChannel.BroadcastQueue.stop(queue)
      Process.delete(:ember_channel_queue)
    end

    result
  end

  defp brodcast_action(action_func, model, opt, event) do
    {from, opts} = Keyword.pop(opts, :from)

    result = action_func.(model, options)

    case result do
      {:ok, res_model} ->
        broadcast(res_model, event, from)
      {:error, changeset} ->
        IO.puts "Error"
      res_model ->
        broadcast(res_model, event, from)
    end

    result
  end

  defp broadcast(model, event, from) do
    queue = Process.get(:ember_channel_queue)

    module = model.__struct__
    topic = module.channel_name <> ":" <> module.channel_scope(model)

    payload = StreamingData.ContactSerializer.format(model)
    if queue do
      EmberChannel.BroadcastQueue.push(queue, topic, event, payload)
    else
      if from do
        %{channel_pid: channel_pid} = from
        @endpoint.broadcast_from channel_pid, topic, event, payload
      else
        @endpoint.broadcast topic, event, payload
      end
    end
  end
end

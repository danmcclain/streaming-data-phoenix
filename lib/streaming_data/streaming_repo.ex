defmodule StreamingData.StreamingRepo do
  @repo StreamingData.Repo
  @endpoint StreamingData.Endpoint

  defdelegate [__adapter__, __log__(entry), config, start_link(opts), in_transaction?,
               stop(pid, timeout), rollback(value), all(queryable, opts), get(queryable, id, opts),
               get!(queryable, id, opts), get_by(queryable, clauses, opts),
               get_by!(queryable, clauses, opts), one(queryable, opts), one!(queryable, opts),
               insert_all(schema_or_source, entries, opts), update_all(queryable, updates, opts),
               delete_all(queryable, opts), preload(struct_or_structs, preloads, opts),
               aggregate(queryable, aggregate, field, opts)], to: @repo

  def insert(model, options \\ []) do
    brodcast_action(&@repo.insert/2, model, options, "new")
  end

  def insert!(model, options \\ []) do
    brodcast_action(&@repo.insert!/2, model, options, "new")
  end

  def update(model, options \\ []) do
    brodcast_action(&@repo.update/2, model, options, "update")
  end

  def update!(model, options \\ []) do
    brodcast_action(&@repo.update!/2, model, options, "update")
  end

  def delete(model, options \\ []) do
    brodcast_action(&@repo.delete/2, model, options, "delete")
  end

  def delete!(model, options \\ []) do
    brodcast_action(&@repo.delete!/2, model, options, "delete")
  end

  def insert_or_update(changeset, options \\ []) do
    brodcast_action(&@repo.insert_or_update!/2, changeset, options, "new")
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

  defp brodcast_action(action_func, model, opts, event) do
    {from, opts} = Keyword.pop(opts, :from)

    result = action_func.(model, opts)

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
        require IEx
        IEx.pry
        IO.inspect @endpoint
        @endpoint.broadcast topic, event, payload
      end
    end
  end
end

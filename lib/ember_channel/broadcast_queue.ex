defmodule EmberChannel.BroadcastQueue do
  use GenServer

  def spawn(endpoint, options) do
    case Supervisor.start_child(EmberChannel.BroadcastQueue.Supervisor, [endpoint, options]) do
      {:ok, pid} ->
        true = Process.link(pid)
        {:ok, pid}
      other -> other
    end
  end

  def push(pid, topic, event, payload) do
    GenServer.call(pid, {:push, topic, event, payload})
  end

  def flush(pid) do
    GenServer.call(pid, :flush)
  end

  def stop(pid) do
    GenServer.stop(pid,:normal)
  end

  def start_link(endpoint, opts \\ []) do
    GenServer.start_link(__MODULE__, [endpoint, opts])
  end

  def init([endpoint, opts]) do
    {:ok, %{endpoint: endpoint, options: opts, queue: []}}
  end

  def handle_call({:push, topic, event, payload}, _from, %{queue: queue} = state) do
    {:reply, :ok, %{state | queue: [{topic, event, payload} | queue]}}
  end

  def handle_call(:flush, _from, %{endpoint: endpoint, queue: queue, options: options} = state) do
    broadcast_queue(queue, endpoint, options)
    {:reply, :ok, state}
  end

  defp broadcast_queue([], endpoint, options), do: nil

  defp broadcast_queue([{topic, event, payload} | rest], endpoint, options) do
    broadcast_queue(rest, endpoint, options)

    if %{channel_pid: channel_pid} = Dict.get(options, :from) do
      endpoint.broadcast_from channel_pid, topic, event, payload
    else
      endpoint.broadcast topic, event, payload
    end
  end
end

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

  def init([endpoint, _opts]) do 
    IO.puts "RUNNING"
    {:ok, %{endpoint: endpoint, queue: []}}
  end

  def handle_call({:push, topic, event, payload}, _from, %{queue: queue} = state) do
    {:reply, :ok, %{state | queue: [{topic, event, payload} | queue]}}
  end

  def handle_call(:flush, _from, %{endpoint: endpoint, queue: queue} = state) do
    # ... broadcast
    broadcast_queue(queue, endpoint)
    {:stop, :normal, :ok, state}
  end

  defp broadcast_queue([], endpoint), do: nil

  defp broadcast_queue([{topic, event, payload} | rest], endpoint) do
    broadcast_queue(rest, endpoint)
    endpoint.broadcast topic, event, payload
  end
end

defmodule EmberChannel.BroadcastQueue.Server do
  use GenServer

  def spawn_queue(endpoint) do
    case Supervisor.start_child(EmberChannel.BroadcastQueue.Supervisor, [endpoint]) do
      {:ok, pid} ->
        true = Process.link(pid)
        {:ok, pid}
      other -> other
    end
  end

  def push(pid, event, record) do
    GenServer.call(pid, {:push, event, record})
  end

  def flush(pid) do
    GenServer.call(pid, :flush)
  end

  def stop(pid) do
    GenServer.stop(pid,:normal)
  end

  def start_link(endpoint) do
    GenServer.start_link(__MODULE__, endpoint)
  end

  def init(endpoint) do 
    IO.puts "RUNNING"
    {:ok, %{endpoint: endpoint, queue: []}}
  end
end

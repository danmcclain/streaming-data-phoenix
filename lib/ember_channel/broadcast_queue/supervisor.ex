defmodule EmberChannel.BroadcastQueue.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(EmberChannel.BroadcastQueue.Server, [], restart: :temporary)
    ]
    supervise children, strategy: :simple_one_for_one
  end
end

defmodule StreamingData.StreamingRepo do
  use EmberChannel.Repo, repo: StreamingData.Repo, endpoint: StreamingData.Endpoint
end

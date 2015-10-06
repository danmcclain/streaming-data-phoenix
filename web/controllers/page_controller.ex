defmodule StreamingData.PageController do
  use StreamingData.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end

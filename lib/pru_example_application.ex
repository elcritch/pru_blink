defmodule PruExample do
  use Application
  require Logger

  def start(_type, _args) do
    PruExample.Supervisor.start_link(name: PruExample.Supervisor)
  end
end

defmodule PruExample.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      worker(PruExample.RemoteShell, [], restart: :transient),
      Plug.Adapters.Cowboy.child_spec(:http, PruExample.Router, [], port: 6969),
    ]

    Supervisor.init(children, strategy: :rest_for_one, max_restarts: 4, max_seconds: 30)
  end
end

defmodule PruExample.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/node" do
    # send_resp(conn, 200, "Welcome")
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "#{inspect Node.self}\n")
  end

  get "/logs" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "#{inspect RingLogger.tail()}\n")
  end

  get "/inet" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "#{inspect :inet.gethostname()}\n")
  end

end


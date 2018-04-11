defmodule PruExample.RemoteShell do
  @moduledoc false

  use GenServer
  require Logger

  ## Client API

  @doc """
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks

  def init(:ok) do
    port = Application.get_env(:remote_ssh, :port, 2222)

    authorized_keys =
      Application.get_env(:remote_ssh, :authorized_keys, [])
      |> Enum.join("\n")
      |> IO.inspect(label: :authorized_keys)

    decoded_authorized_keys = :public_key.ssh_decode(authorized_keys, :auth_keys)

    cb_opts = [authorized_keys: decoded_authorized_keys]

    opts = [
      {:max_sessions, 1},
      {:id_string, :random},
      {:key_cb, {Nerves.Firmware.SSH.Keys, cb_opts}},
      {:system_dir, system_dir() |> IO.inspect(label: :system_dir)},
      {:user_dir, system_dir() },
      {:shell, {Elixir.IEx, :start, []}},
    ] |> IO.inspect(label: :ssh_opts)

    {:ok, _ref} =
      :ssh.daemon port, opts
  end

  def system_dir() do
    cond do
      system_dir = Application.get_env(:remote_ssh, :system_dir) ->
        to_charlist(system_dir)

      File.dir?("/etc/ssh") ->
        to_charlist("/etc/ssh")

      true ->
        :code.priv_dir(:remote_ssh)
    end
  end
end

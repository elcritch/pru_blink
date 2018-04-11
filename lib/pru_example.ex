defmodule PruExample.Initializer do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    Process.send_after self(), :configure, 10_000
    # GenServer.cast(self(), {:configure})
    {:ok, %{}}
  end

  def handle_info(:configure, state) do

    Process.sleep(2_000)

    Logger.info("Init pin overlay")
    BeaglePru.System.configure_pins()

    model = :os.cmd('cat /proc/device-tree/model') |> String.replace(" ", "_")
    Logger.info("Beagle Model: ${inspect model}")
    configure_pins(model)

    BeaglePru.System.boot(0)
    BeaglePru.System.boot(1)

    # TODO: add smart error checking ...
    Process.sleep(1_000)

    {:ok, pid} =
      BeaglePru.RPMsg.start_link(
        31,
        encoder: fn x -> x |> Msgpax.pack!() |> IO.iodata_to_binary() end,
        decoder: fn x -> x |> Msgpax.unpack() end
      )

    # BeaglePru.RPMsg.register(pid)
    Process.sleep(100)
    {:ok, %{}}
  end

  def configure_pins("TI_AM335x_BeagleBone" = model) do
    BeaglePru.System.pin('P8_46', :pruout)
    BeaglePru.System.pin('P8_45', :pruout)
    BeaglePru.System.pin('P8_44', :pruout)
    BeaglePru.System.pin('P8_43', :pruout)
    BeaglePru.System.pin('P8_42', :pruout)
    BeaglePru.System.pin('P8_41', :pruout)
  end

  def configure_pins("TI_AM335x_PocketBeagle" = model) do
    BeaglePru.System.pin('P2_28', :pruout) # PRU0 6
    BeaglePru.System.pin('P2_30', :pruout) # PRU0 3
    BeaglePru.System.pin('P2_32', :pruout) # PRU0 2
    BeaglePru.System.pin('P2_34', :pruout) # PRU0 5

    BeaglePru.System.pin('P1_29', :pruout) # PRU0 7
    BeaglePru.System.pin('P1_31', :pruout) # PRU0 4
    BeaglePru.System.pin('P1_33', :pruout) # PRU0 1
    BeaglePru.System.pin('P1_35', :pruout) # PRU1 10
  end

  def configure_pins(model) do
    raise "Unknown beagle model: ${inspect model}"
  end
end

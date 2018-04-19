defmodule ExScreen.SSD1306.Device do

  # @defaults [device: "i2c-1", reset: nil]
  # @defaults [device: "spidev1.0", reset: nil]

  use GenServer
  use Bitwise
  require Logger

  alias ExScreen.SSD1306.{Commands, Device, Device.Init, Device.Settings, Device.Items}

  alias ElixirALE.{GPIO, I2C, SPI}

  def start_link(%Device.Init{bus: _, address: _, reset_pin: _, dc_pin: _} = config) do
    GenServer.start_link(__MODULE__, [config], name: __MODULE__)
  end

  def display(buffer) when is_binary(buffer), do: GenServer.call(__MODULE__, {:display, buffer})
  def all_on, do: GenServer.call(__MODULE__, :all_on)
  def all_off, do: GenServer.call(__MODULE__, :all_off)
  def reset, do: GenServer.call(__MODULE__, :reset)

  def init([%Device.Init{bus: bus, address: address, reset_pin: reset_pin, dc_pin: dc_pin} = args]) do

    settings = %Device.Settings{}
    config = %ExScreen.SSD1306.Commands{}

    state =
      Map.from_struct(args)
      |> Map.put(:settings, settings)
      |> Map.put(:config, config)

    Logger.info(
      "Connecting to SSD1306 device #{device_name(state)} (#{settings.width}x#{settings.height})"
    )

    iobus =
      case bus do
        "i2c" <> _rem ->
          {:ok, pid} = I2C.start_link(bus, address)
          %IOBus.I2C{pid: pid, bus_name: bus, address: address}
        "spi" <> _rem ->
          spiopts = [mode: 0, speed_hz: 4_000_000  ]
          {:ok, pid} = SPI.start_link(bus, spiopts)
          %IOBus.SPI{pid: pid, bus_name: bus}
        "test" <> _rem ->
          %IOBus.Test{bus_name: bus}
    end

    reset =
      with {:ok, reset_pid} <- GPIO.start_link(reset_pin, :output)
      do
        %IOBus.GPIO{pid: reset_pid, pin: reset_pin}
      end

    dc_pin =
      case dc_pin do
        nil ->
            %IOBus.Empty{bus_name: "empty select_pin"}
        dc_pin ->
          {:ok, dc_pid} = GPIO.start_link(dc_pin, :output)
          %IOBus.GPIO{pid: dc_pid, pin: dc_pin}
      end

    state =
      state
      |> Map.put(:devices, %Device.Devices{iobus: iobus, reset: reset, dcpin: dc_pin})

    case reset_device(state) do
      :ok -> {:ok, state}
      {:error, e} -> {:stop, e}
    end

    {:ok, state}
  end

  def handle_call(:all_on, from, state) do
    buffer = all_on_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call(:all_off, from, state) do
    buffer = all_off_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call(:reset, _from, state) do
    reset_device(state)
    {:reply, :ok, state}
  end

  def handle_call({:display, buffer}, _from, %{width: width, height: height} = state) do
    with :ok <- validate_buffer(buffer, width, height),
         :ok <- Commands.display(state, buffer) do
      {:reply, :ok, state}
    else
      err -> {:reply, err, state}
    end
  end

  def validate_buffer(buffer, width, height) when byte_size(buffer) == width * height / 8,
    do: :ok

  def validate_buffer(buffer, width, height),
    do:
      {:error,
       "Expected buffer of #{div(width * height, 8)} bytes but received buffer of #{
         byte_size(buffer)
       } bytes."}

  def reset_device(%{devices: devices, reset: reset} = state) do
    commands = Map.get(state, :commands, [])

    with :ok <- Commands.reset!(reset),
         :ok <- Commands.initialize!(state),
         :ok <- Commands.display(state, all_off_buffer(state)),
         :ok <- apply_commands(devices, commands),
         :ok <- Commands.display_on!(devices),
         do: :ok
  end

  def all_on_buffer(state), do: initialize_buffer(state.settings, 1)
  def all_off_buffer(state), do: initialize_buffer(state.settings, 0)

  def initialize_buffer(%{width: width, height: height}, value) when value == 0 or value == 1 do
    byte_len = div(width * height, 8)
    bytes = 0..15 |> Enum.reduce(0, fn i, b -> (value <<< i) + b end)
    1..byte_len |> Enum.reduce(<<>>, fn _, buf -> buf <> <<bytes>> end)
  end

  def apply_commands(pid, commands) do
    Enum.reduce(commands, :ok, fn
      _, {:error, _} = error ->
        error

      command, :ok when is_atom(command) ->
        apply(Commands, command, [pid])

      {command, args}, :ok when is_atom(command) and is_list(args) ->
        apply(Commands, command, [pid | args])

      {command, arg}, :ok when is_atom(command) ->
        apply(Commands, command, [pid, arg])
    end)
  end

  def device_name(%{bus: bus, address: nil, reset_pin: reset}),
    do: "#{bus}:--(#{reset})"

  def device_name(%{bus: bus, address: address, reset_pin: reset}),
    do: "#{bus}:#{i2h(address)}(#{reset})"

  def i2h(i), do: "0x" <> Integer.to_string(i, 16)
end

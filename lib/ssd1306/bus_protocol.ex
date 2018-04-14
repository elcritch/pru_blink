defmodule Device.SPI do
  @enforce_keys [:pid, :select_pin]
  defstruct @enforce_keys
end

defmodule Device.I2C do
  @enforce_keys [:pid, :bus_name]
  defstruct @enforce_keys ++ [:address]
end

defmodule Device.GPIO do
  @enforce_keys [:pid, :pin]
  defstruct @enforce_keys
end

defmodule Device.Test do
  @enforce_keys [:name]
  defstruct [:name, :count]
end

defprotocol Device do
  @doc "read data via a given bus"
  def read(device)
  @doc "write data via a given bus"
  def write(device, value)
  @doc "transfer data via a given bus"
  def xfer(device, value)
end

defimpl Device, for: Device.GPIO do
  alias ElixirALE.GPIO

  def read(device), do: GPIO.read(device.pid)
  def write(device, value), do: GPIO.write(device.pid, value)
  def xfer(device, value) do
    res = GPIO.read(device.pid)
    GPIO.write(device.pid)
    res
  end
end

defimpl Device, for: Device.I2C do
  alias ElixirALE.I2C

  def read(%Device.I2C{addres: nil} = device), do: I2C.read(device.pid)
  def read(%Device.I2C{addres: addr} = device), do: I2C.read_device(device.pid, addr)

  def write(%Device.I2C{addres: nil} = device, val), do: I2C.write(device.pid, val)
  def write(%Device.I2C{addres: addr} = device, val), do: I2C.write_device(device.pid, addr, val)

  def xfer(%Device.I2C{addres: nil} = device, value) do
    I2C.write_read(device.pid)
  end

  def xfer(%Device.I2C{addres: addr} = device, value) do
    I2C.write_read_device(device.pid, addr)
  end
end

defimpl Device, for: Device.SPI do
  alias ElixirALE.SPI

  def read(%Device.I2C{select_pin: select_pin} = device) do
    GPIO.write(select_pin, 0)
    res = SPI.transfer(device.pid, << 0x0 >>)
    GPIO.write(select_pin, 1)
    res
  end

  def write(%Device.I2C{select_pin: select_pin} = device) do
    GPIO.write(select_pin, 0)
    SPI.transfer(device.pid, device)
    GPIO.write(select_pin, 1)

    :ok
  end

  def xfer(%Device.I2C{addres: addr} = device, value) do
    GPIO.write(select_pin, 0)
    res = SPI.transfer(device.pid, device)
    GPIO.write(select_pin, 1)

    res
  end
end

defimpl Device, for: Device.Test do
  def read(device) do
    IO.puts("Device send: #{inspect device} value: #{inspect value}")
  end
  def write(device, value) do
    IO.puts("Device send: #{inspect device} value: #{inspect value}")
  end
  def xfer(device, value) do
    IO.puts("Device send: #{inspect device} value: #{inspect value}")
  end
end

# arg = Application.get_env(:ssd1306, :device, %{bus: "i2c-1", address: 0x3c, reset_pin: 24, commands: []})
# state = Application.get_env(:ssd1306, :initial_state, {"HELLO", ["", "", "", "", "", ""]})

defmodule Evil do

  defmacro variable <~ [key, expr] do

    IO.inspect key, label: :key
    IO.inspect expr, label: :expr

    key! = insert_path(variable, key)

    quote do
      var!(unquote(variable)) = Kernel.put_in(unquote(key!), unquote(expr))
    end
  end

  def insert_path(pre, {term, meta, []} = _wrapper), do: {insert_path(pre, term), meta, []}
  def insert_path(pre, {:., meta, args} = _term), do: {:., meta, insert_path(pre, args)}

  def insert_path(pre, [term | rem] = _args),
    do: [insert_path(pre, term) | insert_path(term, rem)]

  def insert_path(pre, [] = _last_arg), do: []
  def insert_path(pre, name) when is_atom(name), do: name

  def insert_path(pre, {prev_head, meta, args}) do
    term = {:., meta, [pre, prev_head]}
    {term, meta, []}
  end
end
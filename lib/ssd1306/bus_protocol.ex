defmodule IOBus.SPI do
  @enforce_keys [:pid, :select_pin]
  defstruct @enforce_keys
end

defmodule IOBus.I2C do
  @enforce_keys [:pid, :bus_name]
  defstruct @enforce_keys ++ [:address]
end

defmodule IOBus.GPIO do
  @enforce_keys [:pid, :pin]
  defstruct @enforce_keys
end

defmodule IOBus.Test do
  @enforce_keys [:name]
  defstruct [:name, :count]
end

defprotocol IOBus do
  @doc "read data via a given bus"
  def read(device)
  @doc "write data via a given bus"
  def write(device, value)
  @doc "transfer data via a given bus"
  def xfer(device, value)
end

defimpl IOBus, for: IOBus.GPIO do
  alias ElixirALE.GPIO

  def read(device), do: GPIO.read(device.pid)
  def write(device, value), do: GPIO.write(device.pid, value)
  def xfer(device, value) do
    res = GPIO.read(device.pid)
    GPIO.write(device.pid)
    res
  end
end

defimpl IOBus, for: IOBus.I2C do
  alias ElixirALE.I2C

  def read(%IOBus.I2C{address: nil} = device), do: I2C.read(device.pid)
  def read(%IOBus.I2C{address: addr} = device), do: I2C.read_device(device.pid, addr)

  def write(%IOBus.I2C{address: nil} = device, val), do: I2C.write(device.pid, val)
  def write(%IOBus.I2C{address: addr} = device, val), do: I2C.write_device(device.pid, addr, val)

  def xfer(%IOBus.I2C{address: nil} = device, value) do
    I2C.write_read(device.pid)
  end

  def xfer(%IOBus.I2C{address: addr} = device, value) do
    I2C.write_read_device(device.pid, addr)
  end
end

defimpl IOBus, for: IOBus.SPI do
  alias ElixirALE.SPI

  def read(%IOBus.SPI{select_pin: select_pin} = device) do
    GPIO.write(select_pin, 0)
    res = SPI.transfer(device.pid, << 0x0 >>)
    GPIO.write(select_pin, 1)
    res
  end

  def write(%IOBus.SPI{select_pin: select_pin} = device) do
    GPIO.write(select_pin, 0)
    SPI.transfer(device.pid, device)
    GPIO.write(select_pin, 1)

    :ok
  end

  def xfer(%IOBus.SPI{select_pin: select_pin} = device, value) do
    GPIO.write(select_pin, 0)
    res = SPI.transfer(device.pid, device)
    GPIO.write(select_pin, 1)

    res
  end
end

defimpl IOBus, for: IOBus.Test do
  def read(device) do
    IO.puts("IOBus read: #{inspect device} ")
  end
  def write(device, value) do
    IO.puts("IOBus write: #{inspect device} value: #{inspect value}")
  end
  def xfer(device, value) do
    IO.puts("IOBus xfer: #{inspect device} value: #{inspect value}")
  end
end

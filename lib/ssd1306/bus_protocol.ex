defmodule Bus.SPI do
  @enforce_keys [:pid, :select_pin]
  defstruct @enforce_keys
end

defmodule Bus.I2C do
  @enforce_keys [:pid, :bus_name, :address]
  defstruct @enforce_keys
end

defmodule Bus.GPIO do
  @enforce_keys [:pid, :pin]
  defstruct @enforce_keys
end

defprotocol Bus.Device do
  @doc "Sends data via a given bus"
  def send(device)
end

defimpl Bus.Device, for: Bus.GPIO do
  alias ElixirALE.GPIO

  def send(device) do
  end
end

defimpl Bus.Device, for: Bus.I2C do
  alias ElixirALE.I2C

  def send(device) do
  end
end

defimpl Bus.Device, for: Bus.SPI do
  alias ElixirALE.SPI

  def send(device) do
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

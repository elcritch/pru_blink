

defmodule ExScreen.SSD1306.Device.Init do
  @enforce_keys [:bus, :address, :reset_pin, :select_pin]
  defstruct @enforce_keys
end


defmodule ExScreen.SSD1306.Device.Settings do
  defstruct [width: 128, height: 64]
end


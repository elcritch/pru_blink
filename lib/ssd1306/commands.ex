defmodule ExScreen.SSD1306.CommandFlags do
  defstruct set_contrast: 0x81,
            display_all_on_resume: 0xA4,
            display_all_on: 0xA5,
            normal_display: 0xA6,
            invert_display: 0xA7,
            display_off: 0xAE,
            display_on: 0xAF,
            set_display_offset: 0xD3,
            set_com_pins: 0xDA,
            set_vcom_detect: 0xDB,
            set_display_clock_div: 0xD5,
            set_pre_charge: 0xD9,
            set_multiplex: 0xA8,
            set_low_column: 0x00,
            set_high_column: 0x10,
            set_start_line: 0x40,
            set_memory_mode: 0x20,
            set_column_address: 0x21,
            set_page_address: 0x22,
            com_scan_inc: 0xC0,
            com_scan_dec: 0xC8,
            set_seg_remap: 0xA0,
            set_charge_pump: 0x8D,
            activate_scroll: 0x2F,
            deactivate_scroll: 0x2E,
            set_vertical_scroll_area: 0xA3,
            right_horizontal_scroll: 0x26,
            left_horizontal_scroll: 0x27,
            vertical_and_right_horizontal_scroll: 0x29,
            vertical_and_left_horizontal_scroll: 0x2A
end

defmodule ExScreen.SSD1306.Commands do
  use Bitwise

  defstruct display_clock_div: 0x80,
            multiplex: 0x3F,
            external_vcc: false,
            # or 0x14 if :external_vcc is true
            charge_pump: 0x10,
            memory_mode: 0x80,
            segment_remap: 0x01,
            com_pins: 0x12,
            # or 0xcf if :external_vcc is true
            contrast: 0x9F,
            # or 0xf1 if :external_vcc is true
            pre_charge: 0x22,
            vcom_detect: 0x40

  @cmds %ExScreen.SSD1306.CommandFlags{}
  @control_register 0x00
  @data_register 0x40

  @doc """
  Reset the SSD1306 using the GPIO reset pin.
  """
  def reset!(gpio_pid) do
    with :ok <- GPIO.write(gpio_pid, 1),
         :ok <- :timer.sleep(1),
         :ok <- GPIO.write(gpio_pid, 0),
         :ok <- :timer.sleep(10),
         :ok <- GPIO.write(gpio_pid, 1),
         do: :ok
  end

  @doc """
  Initialize the device using "sane defaults" based on the display size.

  Configurable options (configure by adding these keys to your device's keys
  in your application configuration) and their defaults below:

      config :ssd1306,
        device: [%{
          display_clock_div: 0x80,
          multiplex: 0x3f,
          external_vcc: false,
          charge_pump: 0x10, # or 0x14 if :external_vcc is true
          memory_mode: 0x80,
          segment_remap: 0x01,
          com_pins: 0x12,
          contrast: 0x9f, # or 0xcf if :external_vcc is true
          pre_charge: 0x22, # or 0xf1 if :external_vcc is true
          vcom_detect: 0x40
        }]
  """
  def initialize!(%{device: device, config: config}) do
    {:ok, ^device} =
      {:ok, device}
      |> display_off!()
      |> display_clock_div(config.display_clock_div || 0x80)
      |> display_clock_div(config.display_clock_div || 0x80)
      |> multiplex(config.multiplex || 0x3F)
      |> display_offset(0)
      |> start_line(0)
      |> charge_pump(config.charge_pump || vcc_is_external(config, 0x10, 0x14))
      |> memory_mode(config.memory_mode || 0x00)
      |> segment_remap(config.segment_remap || 0x01)
      |> com_scan_dec!()
      |> com_pins(config.com_pins || 0x12)
      |> contrast(config.contrast || vcc_is_external(config, 0x9F, 0xCF))
      |> pre_charge(config.pre_charge || vcc_is_external(config, 0x22, 0xF1))
      |> vcom_detect(config.vcom_detect || 0x40)
      |> display_all_on_resume!()
      |> normal_display!()

    :ok
  end

  @doc """
  Send a frame to the display.

  Arguments:
    * A map with `:i2c` set to the I2c connection pid, `:width` and `:height in pixels.
    * A bytestring containing the buffer to be displayed.
  """
  def display(%{device: device, settings: %{width: width, height: height}}, buffer) do
    pages = div(height, 8)

    {:ok, ^device} =
      {:ok, device}
      |> column_address(0, width - 1)
      |> page_address(0, pages - 1)
      |> send_buffer(buffer)

    :ok
  end

  def contrast(dev, value), do: send_command(dev, [@cmds.set_contrast, value])
  def display_all_on_resume!(dev), do: send_command(dev, @cmds.display_all_on_resume)
  def display_all_on!(dev), do: send_command(dev, @cmds.display_all_on)
  def normal_display!(dev), do: send_command(dev, @cmds.normal_display)
  def invert_display!(dev), do: send_command(dev, @cmds.invert_display)
  def display_off!(dev), do: send_command(dev, @cmds.display_off)
  def display_on!(dev), do: send_command(dev, @cmds.display_on)
  def display_offset(dev, value), do: send_command(dev, [@cmds.set_display_offset, value])
  def com_pins(dev, value), do: send_command(dev, [@cmds.set_com_pins, value])
  def vcom_detect(dev, value), do: send_command(dev, [@cmds.set_vcom_detect, value])
  def display_clock_div(dev, value), do: send_command(dev, [@cmds.set_display_clock_div, value])
  def pre_charge(dev, value), do: send_command(dev, [@cmds.set_pre_charge, value])
  def multiplex(dev, value), do: send_command(dev, [@cmds.set_multiplex, value])

  # def low_column(dev, value),                     do: send_commands(dev, [@cmds.set_low_column, value])
  # def high_column(dev, value),                    do: send_commands(dev, [@cmds.set_high_column, value])
  def start_line(dev, value), do: send_command(dev, @cmds.set_start_line ||| value)
  def memory_mode(dev, value), do: send_command(dev, [@cmds.set_memory_mode, value])

  def column_address(dev, start, fin),
    do: send_command(dev, [@cmds.set_column_address, start, fin])

  def page_address(dev, start, fin), do: send_command(dev, [@cmds.set_page_address, start, fin])
  def com_scan_inc!(dev), do: send_command(dev, @cmds.com_scan_inc)
  def com_scan_dec!(dev), do: send_command(dev, @cmds.com_scan_inc)
  def segment_remap(dev, value), do: send_command(dev, @cmds.set_seg_remap ||| value)
  def charge_pump(dev, value), do: send_command(dev, [@cmds.set_charge_pump, value])
  def activate_scroll!(dev), do: send_command(dev, @cmds.activate_scroll)
  def deactivate_scroll!(dev), do: send_command(dev, @cmds.deactivate_scroll)

  def vertical_scroll_area(dev, value),
    do: send_command(dev, [@cmds.set_vertical_scroll_area, value])

  def right_horizontal_scroll!(dev), do: send_command(dev, @cmds.right_horizontal_scroll)
  def left_horizontal_scroll!(dev), do: send_command(dev, @cmds.left_horizontal_scroll)

  def vertical_and_right_horizontal_scroll!(dev),
    do: send_command(dev, @cmds.vertical_and_right_horizontal_scroll)

  def vertical_and_left_horizontal_scroll!(dev),
    do: send_command(dev, @cmds.vertical_and_left_horizontal_scroll)

  def send_command(device, command) when is_list(command) do
    for byte <- command do
      :ok = send_command(device, byte)
    end
  end

  def send_command({:ok, device}, byte) do
    {send_command(device, byte), device}
  end

  def send_command(device, byte) do
    :ok = IOBus.send(device, <<@control_register, byte>>)
  end

  defp send_data(device, <<msb::integer-size(8), lsb::integer-size(8)>>) do
    IOBus.send(device, <<@data_register, msb, lsb>>)
  end

  defp send_buffer(device, <<_::integer-size(8), _::integer-size(8)>> = buffer) do
    send_data(device, buffer)
  end

  defp send_buffer(device, <<msb::integer-size(8), lsb::integer-size(8), rest::binary>>) do
    with :ok <- send_data(device, <<msb, lsb>>),
         :ok <- send_buffer(device, rest),
         do: :ok
  end

  defp vcc_is_external(%{external_vcc: true}, value, _), do: value
  defp vcc_is_external(_, _, value), do: value
end

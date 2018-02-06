defmodule PruBlink do
  use Application
  require Pru
  require Logger

  def start(_type, _args) do
    Logger.info("Init pin overlay")
    Pru.init_pins()
    Logger.info("Set P8_11 pin to pruout")

    Pru.pin_in('P8_46')
    Pru.pin_in('P8_45')
    Pru.pin_out('P8_44')
    Pru.pin_out('P8_43')
    Pru.pin_out('P8_41')
    Pru.pin_out('P8_39')

    Pru.pin_out('P8_27')
    Pru.pin_out('P8_28')
    {:ok, self()}
  end
end

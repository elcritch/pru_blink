# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize the firmware. Uncomment all or parts of the following
# to add files to the root filesystem or modify the firmware
# archive.
config :logger, level: :debug

# config :nerves, :firmware,
#   rootfs_overlay: "rootfs_overlay",
#   fwup_conf: "config/fwup.conf"

config :pru_blink, interface: :eth0
#config :hello_network, interface: :wlan0
#config :hello_network, interface: :usb0

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"

config :nerves_network, :default,
  eth0: [
    ipv4_address_method: :dhcp
  ]

config :bootloader,
  init: [:nerves_runtime, :nerves_network, :nerves_init_gadget],
  app: :pru_blink


config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay"

# config :nerves_firmware_ssh,
#   authorized_keys: [
#     File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
#   ]


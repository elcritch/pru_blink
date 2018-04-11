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


config :esshd,
  enabled: true,
  priv_dir: "/tmp/priv_ssh/",
  handler: "Sshd.ShellHandler.Elixir",
  port: 10_022,
  public_key_authenticator: "PruExample.AuthorizedKeys"

target = System.get_env("MIX_TARGET") || "host"

if target != "host" do
  config :logger, backends: [RingLogger]
  config :logger, RingLogger, max_size: 2_000
end

# config :pru_example, interface: :usb0

# Boot Shoehorn first and have it start our app.
config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: :pru_example

# config :nerves_init_gadget,
#   ifname: "usb0",
#   address_method: :linklocal,
#   mdns_domain: "nerves.local",
#   node_name: nil,
#   node_host: :mdns_domain

# config :nerves_network, :default,
#   usb0: [
#     ipv4_address_method: :linklocal,
#     # ipv4_address: "169.254.40.40",
#   ]

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcp,
  mdns_domain: "pru-example.local",
  node_name: "pru_example",
  node_host: :mdns_domain

config :nerves_firmware_ssh,
  authorized_keys: File.read!("./rootfs_overlay/etc/ssh/authorized_keys") |> String.trim() |> String.split("\n")

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :remote_ssh,
  port: 2020,
  system_dir: "#{ if System.get_env("MIX_TARGET") == "host", do: "rootfs_overlay", else: ""}/etc/ssh",
  authorized_keys: File.read!("./rootfs_overlay/etc/ssh/authorized_keys") |> String.trim() |> String.split("\n")


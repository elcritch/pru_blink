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

config :nerves_network, :default,
  usb0: [
    ipv4_address_method: :linklocal,
    # ipv4_address: "169.254.40.40",
  ]

config :nerves_init_gadget,
  ifname: "eth0",
  address_method: :dhcp,
  mdns_domain: "pru-example.local",
  node_name: "pru_example",
  node_host: :mdns_domain

authorized_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNnURXeZ846e2KLM6IEePF8U5F5C58bDMdCCWdlJi189ISKUsfA8i9GIm+2y2H0PAYL2NrW3Ey+9cfALMLIGQGDeWpLWd/VkNr/eAVJ/8mEreNeRbWYfLHWRIfk4qLWt5fXlkfiEywLYetZBJXdoa9F/2NlMZX1kbKNEVQD0gREaQaOnRNSimHDPzMficiJcdlFT1Jdu+cxjleto0rEwiBJhWf5EygTlDaB5PN1CLt7b2tBhmyfHPw4etBGfAvL8Dyl0a+xVh64YEyO7LfXyDQOXJaidtcH3Abc/N4IiJXHSqxipqao64Tzi9mgTn6D84DatuOYfabSl3WLDGHJSka5LIPU+y36YovpgeKvYVTU4O/2kyBoSd8kaTL6uXD0oSCnrEHThHLTcrSzuCjMIM1dCXN+G6bhW47chOEHfw3G0ZnY/SyR/7S5xQ0FZwJf0ub++Scf//yaOECMViAn+1T/qBsJNMKeRcv3fPFeMdkO8mWD+qpHaJD1nmVvZD+UVhqmTou5WhKFiIqc3v1+WZ7SXIlWqIchWsje84LOqeLyylnyKYqkVKGDIHOLAWR5WEgPXtKm0hfBwPqlfit12vuqLpYL1Er3o+E45Hb1b6VHyt/Yo86A3XlQ1V1ETkJMXWAeRM1Ne5OQuKG9jyP/p+rvbn04kqjY+LPeysSgr9KrQ=="
]

config :nerves_firmware_ssh,
  authorized_keys: authorized_keys

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :iex_ssh_shell,
  port: 2222,
  system_dir: "#{ if System.get_env("MIX_TARGET") == "host", do: "rootfs_overlay", else: ""}/etc/ssh",
  authorized_keys: authorized_keys


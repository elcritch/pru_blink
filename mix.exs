defmodule PruExample.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  Mix.shell().info([
    :green,
    """
    Mix environment
      MIX_TARGET:   #{@target}
      MIX_ENV:      #{Mix.env()}
    """,
    :reset
  ])

  def project do
    [
      app: :pru_example,
      version: "0.1.0",
      elixir: "~> 1.4",
      compilers: Mix.compilers() ++ (if @target != "host", do: [:elixir_make], else: []),
      make_clean: ["clean"],
      # Previous method: hardcode path
      # make_env: %{ "PRU_CGT" => System.user_home() <> "/.nerves/artifacts/extras_toolchain_pru_cgt-portable-0.1.0/ti-cgt-pru/"},
      target: @target,
      # archives: [nerves_bootstrap: "~> 0.6"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(@target),
      # aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  def application, do: application(@target)

  def application("host") do
    [mod: {PruExample, []}, extra_applications: [:logger, :ssh, :public_key]]
  end

  def application(_target) do
    [mod: {PruExample, []}, extra_applications: [:logger, :ssh, :public_key]]
  end

  def deps do
    [
      # Provides default `toolchain_extras` platform
      #    placing it in a nerves branch, otherwise the dependency build order gets tricky
      #    and I don't know how to force the deps.compile order
      # {:nerves, github: "elcritch/nerves", branch: "host_tools_fork", override: true},
      {:nerves, "1.0.0"},

      {:msgpax, "~> 2.1"},
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.3"},

    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: [
  ]

  def deps(target) do
    [
      {:elixir_ale, "~> 1.0"},
      {:elixir_make, "~> 0.3"},

      {:nerves_runtime, "~> 0.5"},
      {:nerves_network, "~> 0.3"},
      {:nerves_network_interface, "~> 0.4"},
      {:nerves_firmware_ssh, "~> 0.2"},
      {:shoehorn, "~> 0.2"},
      {:nerves_init_gadget, "~> 0.2"},
      {:ring_logger, "~> 0.4"},

      # {:adafruit_display, "~> 0.1.0", github: "elcritch/adafruit_display", },
      # {:adafruit_display, "~> 0.1.0", path: "../contracts/adafruit_display/", },

      # Toolchain Extras for PRU CGT Compiler, set $PRU_CGT
      # {:toolchain_extras_pru_cgt, "~> 2.2.1",
      # github: "elcritch/extras_toolchain_pru_cgt", branch: "master", runtime: true, override: true},

      # PRU Library support, sets $PRU_LIB
      {:beagle_pru_support, "~> 0.7", github: "elcritch/beagle_pru_support", runtime: false},

      # PRU Library support, sets $PRU_LIB
      {:beagle_pru_interface, "~> 0.1", github: "elcritch/beagle_pru_interface", runtime: true}

    ] ++ system(target)
  end

  def system("bbb"), do: [{:nerves_system_bbb, "~> 1.0.0", runtime: false}]
  def system("bbb_ti"),
      do: [
      {:nerves_system_bbb_ti, "~> 1.0.1-rc.0-kern-v4.9.82-v2",
       github: "elcritch/nerves_system_bbb_ti", branch: "linux-4.9-ti-rt", runtime: false}
    ]

  def system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []

  def aliases(_target) do
    [loadconfig: [&bootstrap/1]]
    # |> Nerves.Bootstrap.add_aliases()
  end

  defp bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end
end

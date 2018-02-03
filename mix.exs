defmodule PruBlink.Mixfile do
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
      compilers: [:elixir_make | Mix.compilers()],
      make_clean: ["clean"],
      # Previous method: hardcode path
      # make_env: %{ "PRU_CGT" => System.user_home() <> "/.nerves/artifacts/extras_toolchain_pru_cgt-portable-0.1.0/ti-cgt-pru/"},
      target: @target,
      archives: [nerves_bootstrap: "~> 0.6"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(@target),
      deps: deps()
    ]
  end

  def application, do: application(@target)

  def application("host") do
    [extra_applications: [:logger]]
  end

  def application(_target) do
    [mod: {PruBlink, []}, extra_applications: [:logger]]
  end

  def deps do
    [
      # Provides default `toolchain_extras` platform
      #    placing it in a nerves branch, otherwise the dependency build order gets tricky
      #    and I don't know how to force the deps.compile order
      {:nerves, github: "elcritch/nerves", branch: "host_tools_fork", override: true},

      {:elixir_make, "~> 0.3"},
      {:msgpax, "~> 2.1"},
      {:elixir_ale, "~> 1.0"},

      # Toolchain Extras for PRU CGT Compiler, set $PRU_CGT
      {:toolchain_extras_pru_cgt, "~> 0.2",
       github: "elcritch/extras_toolchain_pru_cgt",
       branch: "master"},

      # PRU Library support, sets $PRU_LIB 
      {:nerves_pru_support,
       git: "https://github.com/elcritch/nerves_pru_support.git", branch: "master"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: []

  def deps(target) do
    [
      {:nerves_runtime, "~> 0.5"},
      {:nerves_network, "~> 0.3"},
      {:nerves_network_interface, "~> 0.4"},
      {:nerves_firmware_ssh, "~> 0.2"}
    ] ++ system(target)
  end

  def system("bbb"), do: [{:nerves_system_bbb, "~> 0.20.0", runtime: false}]
  def system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []

  def aliases(_target) do
    [] |> Nerves.Bootstrap.add_aliases()
  end
end

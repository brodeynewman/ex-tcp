defmodule Tcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tcp,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env(), [:logger]),
      mod: {Tcp.Application, []}
    ]
  end

  defp extra_applications(:dev, default), do: default ++ [:lettuce]
  defp extra_applications(_, default), do: default

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:lettuce, "~> 0.1.5", only: :dev}
    ]
  end
end

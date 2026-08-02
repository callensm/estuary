defmodule Estuary.MixProject do
  use Mix.Project

  def project do
    [
      app: :estuary,
      version: "0.1.1",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      license: ["Apache-2.0"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Estuary.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 4.1.1"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_sqs, "~> 3.4.0"},
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.4.0"},
      {:saxy, "~> 1.1.0"},
      {:websockex, "~> 0.5.1"},
      {:yaml_elixir, "~> 2.12.2"}
    ]
  end
end

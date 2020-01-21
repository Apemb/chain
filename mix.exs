defmodule Chain.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :chain,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      name: "Chain",
      description: "JS Promise inspired data pipeline",
      source_url: "https://github.com/apemb/chain",
      docs: [
        main: "Chain",
        source_ref: "v.#{@version}"
      ],
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Antoine Boileau"],
      links: %{
        "GitHub" => "https://github.com/apemb/chain"
      }
    }
  end
end


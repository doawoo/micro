defmodule Micro.Args do
  require Logger

  @options [
    port: :integer
  ]

  def parse(raw_args) when is_list(raw_args) do
    if started_in_burrito?(raw_args) do
      ["--no-halt", "--", "start" | real_args] = raw_args
      {parsed, _, _} = OptionParser.parse(real_args, switches: @options)

      [
        port: Keyword.get(parsed, :port, default_port()),
      ]
    else
      [
        port: default_port(),
      ]
    end
  end

  defp started_in_burrito?(args), do: match?(["--no-halt", "--", "start" | _args], args)

  defp default_port, do: 3000
end

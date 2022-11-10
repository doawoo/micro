defmodule Micro.ConfigFile do
  require Logger

  def read_or_create() do
    path = File.cwd!() |> Path.join("micro_config.json")

    if !File.exists?(path) do
      IO.puts("ERROR: No configuration file was found!")
      System.halt(1)
    end

    try do
      File.read!(path) |> Jason.decode!() |> load_configs()
    rescue
      e ->
        Logger.error("Error reading config file: #{inspect(e)}")
    end
  end

  defp load_configs(configs) when is_list(configs) do
    Enum.map(configs, fn cfg ->
      Logger.debug("Micro :: Config :: Loaded config for '#{cfg["hostname"]}' [#{cfg["page_dir"]}]")

      Micro.PageServer.new(
        hostname: cfg["hostname"],
        page_dir: cfg["page_dir"],
        dev_mode: cfg["dev_mode"]
      )
    end)
  end
end

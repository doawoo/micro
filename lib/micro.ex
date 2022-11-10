defmodule Micro do
  use Application

  require Logger

  @impl Application
  def start(_, _) do
    args_parsed = Micro.Args.parse(Burrito.Util.Args.get_arguments())
    options = [callback: Micro.Handler] ++ args_parsed

    Logger.debug("Micro :: init :: #{inspect(options)}")

    children = [
      {Micro.Supervisor, []},
      Registry.child_spec(keys: :unique, name: Micro.PageServerRegistry),
      %{id: :elli, start: {:elli, :start_link, [options]}}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end

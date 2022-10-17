defmodule Micro.Supervisor do
  use Supervisor

  require Logger

  alias Micro.Options

  def start_link(_, _) do
    args_parsed = Options.parse(Burrito.Util.Args.get_arguments())
    options = [callback: Micro.Handler] ++ args_parsed
    Supervisor.start_link(__MODULE__, options)
  end

  def init(options) do
    children = [
      {Micro.PageServer, options},
      %{id: :elli, start: {:elli, :start_link, [options]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

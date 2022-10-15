defmodule Micro.Supervisor do
  use Supervisor

  def start_link(ref, options) do
    Supervisor.start_link(__MODULE__, options, name: ref)
  end

  def init(options) do
    children = [
      {Micro.PageServer, []},
      %{id: :elli, start: {:elli, :start_link, [options]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

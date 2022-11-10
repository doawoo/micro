defmodule Micro.Supervisor do
  use DynamicSupervisor

  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_new_server(Micro.PageServer.t()) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_new_server(%Micro.PageServer{} = server_config) do
    child_specification = {Micro.PageServer, server_config}
    DynamicSupervisor.start_child(__MODULE__, child_specification)
  end

  @spec lookup_server(String.t()) :: pid() | nil
  def lookup_server(hostname) do
    lookup_result = Registry.lookup(Micro.PageServerRegistry, hostname)
    if length(lookup_result) != 1 do
      nil
    else
      [{server_pid, _hostname}] = lookup_result
      server_pid
    end
  end
end

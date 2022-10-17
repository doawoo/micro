defmodule Micro do
  use Application

  @spec start(term(), term()) :: {:ok, pid}
  def start(_, _) do
    Micro.Supervisor.start_link(__MODULE__, [])
  end

  def get_error_page(404), do: Micro.Pages.Errors.NotFound
  def get_error_page(500), do: Micro.Pages.Errors.InternalServerError
end

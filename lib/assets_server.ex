defmodule Micro.AssetsServer do
  use GenServer

  alias Micro.PageServer

  require Logger

  @spec start_link(Keyword.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  @spec init(keyword) :: {:ok, %{dir: binary}}
  def init(options) do
    Logger.debug("AssetServer :: init :: #{inspect(options)}")

    pages_dir = Keyword.get(options, :dir, PageServer.default_pages_dir())

    init_state = %{
      dir: pages_dir
    }

    {:ok, init_state}
  end

  @impl GenServer
  def handle_call({:get_asset, path}, _from, state) do
    full_path = compute_asset_path(state.dir, path)

    if File.exists?(full_path) do
      content = File.read!(full_path)
      {:reply, content, state}
    else
      Logger.warn("AssetServer :: #{full_path} :: File cannot be found")
      {:reply, nil, state}
    end
  end

  @spec get_asset(any) :: term() | nil
  def get_asset(path) do
    GenServer.call(__MODULE__, {:get_asset, path})
  end

  def guess_content_type(path) do
    MIME.from_path(path)
  end

  defp compute_asset_path(page_dir, asset_path), do: Path.join(page_dir, ["static/", asset_path])
end

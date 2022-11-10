defmodule Micro.PageServer do
  @moduledoc """
  GenServer and Typed Struct that defines a "Micro" server.
  Fields:

  * `:hostname` - A `URI.t()` struct that describes the hostname this server will serve/match against.
  * `:page_dir` - Path to the scripts on disk you wish to serve.
  * `:dev_mode` - Should the server re-load and re-compile scripts as they change on disk?
  """

  use TypedStruct
  use GenServer

  require Logger

  typedstruct do
    field :hostname, String.t(), enforce: true
    field :page_dir, String.t(), enforce: true
    field :dev_mode, boolean(), enforce: true
  end

  @spec new(keyword) :: Micro.PageServer.t()
  def new(options) do
    %__MODULE__{
      hostname: Keyword.get(options, :hostname, URI.new!("http://localhost")),
      page_dir: Keyword.get(options, :page_dir, File.cwd!()),
      dev_mode: Keyword.get(options, :dev_mode, false)
    }
  end

  def start_link(%__MODULE__{} = settings) do
    GenServer.start_link(__MODULE__, settings, name: {:via, Registry, {Micro.PageServerRegistry, settings.hostname.host}})
  end

  @impl GenServer
  def init(%__MODULE__{} = server_settings) do
    Logger.debug("PageServer :: init :: #{inspect(server_settings)}")

    # Listen for file changes if we're in dev mode
    if server_settings.dev_mode do
      {:ok, pid} = FileSystem.start_link(dirs: [server_settings.page_dir])
      FileSystem.subscribe(pid)
    end

    {:ok, %{
      settings: server_settings,
      pages_cache: load_all_pages(server_settings.page_dir)
    }}
  end

  @impl GenServer
  def handle_call({:load_file, path}, _from, state) do
    {result, new_state} = do_load_page(path, state.pages_cache, state.settings.page_dir)
    {:reply, result, new_state}
  end

  def handle_call({:get_page, segments}, _from, state) do
    maybe_page = Map.get(state.pages_cache, segments)
    {:reply, maybe_page, state}
  end

  def handle_call({:get_asset, path}, _from, state) do
    full_path = compute_asset_path(state.settings.page_dir, path)

    if File.exists?(full_path) do
      content = File.read!(full_path)
      {:reply, content, state}
    else
      Logger.warn("PageServer :: #{full_path} :: Asset cannot be found")
      {:reply, nil, state}
    end
  end

  @spec load_page(pid, any) :: :ok | :error
  def load_page(server, path) do
    GenServer.call(server, {:load_file, path})
  end

  @spec get_page(pid, list()) :: nil | atom()
  def get_page(server, segments) when is_list(segments) do
    GenServer.call(server, {:get_page, segments})
  end

  @spec get_asset(pid, any) :: term() | nil
  def get_asset(server, path) do
    GenServer.call(server, {:get_asset, path})
  end

  def guess_content_type(path) do
    MIME.from_path(path)
  end

  #### File Change Events

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    page_map = do_load_page(path, state.pages_cache, state.settings.page_dir)
    {:noreply, %{state | pages_cache: page_map}}
  end

  #### Private Helpers

  defp load_all_pages(dir) do
    ls_r(dir)
    |> Enum.reduce(%{}, fn path, acc ->
      do_load_page(path, acc, dir)
    end)
  end

  defp ls_r(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat()

      true ->
        []
    end
  end

  defp do_load_page(path, page_map, page_dir) do
    if Path.extname(path) != ".exs" || !File.exists?(path) do
      page_map
    else
      case catch_eval(path) do
        {{:module, module_name, _module_code, _functions}, []} ->
          clean_path = compute_clean_path(path, page_dir)
          Logger.debug("PageServer :: Loaded File :: #{path} :: #{inspect(clean_path)}")
          Map.put(page_map, clean_path, module_name)
        _ ->
          page_map
      end
    end
  end

  defp compute_clean_path(path, pages_dir) do
    Path.relative_to(path, pages_dir)
    |> Path.split()
    |> Enum.map(fn item -> String.replace_suffix(item, ".exs", "") end)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.reject(fn item -> item == "index" end)
  end

  defp compute_asset_path(page_dir, asset_path), do: Path.join(page_dir, ["static/", asset_path])

  defp catch_eval(path) do
    try do
      Code.eval_file(path)
    rescue
      e ->
        Logger.error("PageServer :: #{path} :: #{inspect(e)}")
        :error
    end
  end
end

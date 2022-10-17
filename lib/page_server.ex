defmodule Micro.PageServer do
  use GenServer

  require Logger

  def default_pages_dir, do: "./pages"

  @spec start_link(Keyword.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  def init(options) do
    Logger.debug("PageServer :: init :: #{inspect(options)}")

    pages_dir = Keyword.get(options, :dir, default_pages_dir())

    # Listen for file changes
    {:ok, pid} = FileSystem.start_link(dirs: [pages_dir])
    FileSystem.subscribe(pid)

    init_state = load_all_pages(pages_dir)

    {:ok, init_state}
  end

  @impl GenServer
  def handle_call({:load_file, path}, _from, state) do
    {result, new_state} = do_load_page(path, state)
    {:reply, result, new_state}
  end

  def handle_call({:get_page, segments}, _from, state) do
    maybe_page = Map.get(state.pages, segments)
    {:reply, maybe_page, state}
  end

  @spec load_page(any) :: :ok | :error
  def load_page(path) do
    GenServer.call(__MODULE__, {:load_file, path})
  end

  @spec get_page(list()) :: nil | atom()
  def get_page(segments) when is_list(segments) do
    GenServer.call(__MODULE__, {:get_page, segments})
  end

  #### File Change Events

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, {path, events}}, state) do
    Logger.debug("File Event: #{inspect(path)} :: #{inspect(events)}")
    {_result, new_state} = do_load_page(path, state)
    {:noreply, new_state}
  end

  #### Private Helper Functions

  defp load_all_pages(directory) do
    ls_r(directory)
    |> Enum.reduce(%{pages: %{}, dir: directory}, fn path, acc ->
      {_res, new_acc} = do_load_page(path, acc)
      new_acc
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

  defp do_load_page(path, state) do
    if Path.extname(path) != ".exs" || !File.exists?(path) do
      {:error, state}
    else
      case catch_eval(path) do
        {{:module, module_name, _module_code, _functions}, []} ->
          Logger.debug("PageServer :: Loaded File :: #{path}")

          clean_path = module_name.__micro_page(:path)
          new_pages = Map.put_new(state.pages, clean_path, module_name)
          new_state = %{state | pages: new_pages}
          {:ok, new_state}

        _ ->
          {:error, state}
      end
    end
  end

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

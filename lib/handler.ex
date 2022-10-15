defmodule Micro.Handler do
  @behaviour :elli_handler

  alias :elli_request, as: Request

  require Logger

  def handle(req, _args) do
    # handle(Request.method(req), Request.path(req), req, args)
    path = Request.path(req)
    params_get = Request.get_args(req)
    params_post = Request.post_args(req)
    headers = Request.headers(req)

    params = %{get: params_get, post: params_post, headers: headers}

    maybe_page = Micro.PageServer.get_page(path)

    if maybe_page == nil do
      render_error(404, params)
    else
      {200, [], maybe_page.__micro_page(:render, params)}
    end
  end

  def handle_event(event, args, config) do
    Logger.debug("#{inspect(event)} :: #{inspect(args)} :: #{inspect(config)}")
    :ok
  end

  defp render_error(code, params) do
    page_mod = Micro.get_error_page(code)
    {code, [], page_mod.__micro_page(:render, params)}
  end
end

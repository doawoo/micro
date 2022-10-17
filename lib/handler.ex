defmodule Micro.Handler do
  @behaviour :elli_handler

  alias :elli_request, as: Request
  alias Micro.{AssetsServer, PageServer}

  require Logger

  def handle(req, _args) do
    path = Request.path(req)
    handle_path(path, req)
  end

  defp handle_path(["static" | asset_path], req) do
    asset_path = Path.join(asset_path)
    maybe_asset = AssetsServer.get_asset(asset_path)
    params = extract_params(req)

    if maybe_asset == nil do
      render_error(404, params)
    else
      content_type = AssetsServer.guess_content_type(asset_path)
      {200, [{"Content-Type", content_type}], maybe_asset}
    end
  end

  defp handle_path(path, req) do
    maybe_page = PageServer.get_page(path)
    params = extract_params(req)

    if maybe_page == nil do
      render_error(404, params)
    else
      Process.put(:params, params)
      page_content = maybe_page.__micro_page(:render)
      resp_headers = Process.get(:headers, [])
      {200, resp_headers, page_content}
    end
  end

  def handle_event(_event, _args, _config) do
    :ok
  end

  defp render_error(code, params) do
    Logger.debug("HTTP :: render_error :: #{code}")

    page_mod = Micro.get_error_page(code)
    {code, [], page_mod.__micro_page(:render, params)}
  end

  defp extract_params(req) do
    params_get = Request.get_args(req)
    params_post = Request.post_args(req)
    headers = Request.headers(req)

    %{get: params_get, post: params_post, headers: headers}
  end
end

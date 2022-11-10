defmodule Micro.Handler do
  @behaviour :elli_handler

  alias :elli_request, as: Request
  alias Micro.PageServer

  require Logger

  def handle(req, _args) do
    path = Request.path(req)
    handle_path(path, req)
  end

  defp handle_path(["static" | asset_path], req) do
    host_uri = maybe_get_host(req)
    server = Micro.Supervisor.lookup_server(host_uri.host)
    asset_path = Path.join(asset_path)
    maybe_asset = PageServer.get_asset(server, asset_path)
    params = extract_params(req)

    if maybe_asset == nil do
      render_error(404, params)
    else
      content_type = PageServer.guess_content_type(asset_path)
      {200, [{"Content-Type", content_type}], maybe_asset}
    end
  end

  defp handle_path(path, req) do
    host_uri = maybe_get_host(req)
    server = Micro.Supervisor.lookup_server(host_uri.host)

    if server == nil do
      {404, [], "Hostname not registered"}
    else
      maybe_page = PageServer.get_page(server, path)
      params = extract_params(req)

      if maybe_page == nil do
        render_error(404, params)
      else
        Process.put(:params, params)

        try do
          page_content = maybe_page.__micro_page(:render)
          resp_headers = Process.get(:headers, [])
          {200, resp_headers, page_content}
        rescue
          e ->
            Logger.error(Exception.format(:error, e, __STACKTRACE__))
            render_error(500, params)
        end
      end
    end
  end

  def handle_event(_event, _args, _config) do
    :ok
  end

  defp maybe_get_host(req) do
    {_, host} =
      Request.headers(req) |> Enum.find({"Host", :undefined}, fn {k, _v} -> k == "Host" end)

    if host == :undefined do
      "http://localhost" |> URI.parse()
    else
      "http://#{host}" |> String.downcase() |> URI.parse()
    end
  end

  defp render_error(code, _params) do
    Logger.debug("HTTP :: render_error :: #{code}")
    Process.put(:error_code, code)
    {code, [], Micro.GenericError.__micro_page(:render)}
  end

  defp extract_params(req) do
    params_get = Request.get_args(req)
    params_post = Request.post_args(req)
    headers = Request.headers(req)

    %{get: params_get, post: params_post, headers: headers}
  end
end

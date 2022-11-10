defmodule Micro.Page do
  defmacro __using__(_options) do
    quote do
      import Micro.Page
      import Temple
      alias :elli_request, as: Request
    end
  end

  defmacro page(do: block) do
    quote do
      def __micro_page(:path) do
        Micro.Page.compute_path(__ENV__)
      end

      def put_resp_header(name, value) when is_binary(name) and is_binary(value) do
        existing_headers = Process.get(:headers, [])
        new_headers = [ {name, value} | existing_headers]
        Process.put(:headers, new_headers)
      end

      def params(), do: Process.get(:params, %{})

      def __micro_page(:render) do
        temple do
          unquote(block)
        end
      end
    end
  end

  def compute_path(caller) do
    caller.file
  end
end

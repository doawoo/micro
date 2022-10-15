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
        Micro.Page.compute_path(__MODULE__)
      end

      def __micro_page(:render, req) do
        temple do
          unquote(block)
        end
      end
    end
  end

  def compute_path(caller) do
    ["Micro", "Pages" | rest_path] = Module.split(caller)
    cased = Enum.map(rest_path, &Macro.underscore/1)
    Enum.filter(cased, fn item ->
      item != "index"
    end)
  end
end

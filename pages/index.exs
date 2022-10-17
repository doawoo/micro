defmodule Micro.Pages.Index do
  use Micro.Page

  def get_title, do: "Micro - Just get the thing online."
  def get_page_dir, do: :sys.get_state(Micro.PageServer).dir
  def get_page_map, do: :sys.get_state(Micro.PageServer).pages

  page do
    "<!DOCTYPE html>"
    html do
      head do
        meta charset: "utf-8"
        meta http_equiv: "X-UA-Compatible", content: "IE=edge"
        meta name: "viewport", content: "width=device-width, initial-scale=1.0"
        link rel: "stylesheet", href: "/static/css/pico.classless.min.css"

        title do: "#{get_title()}"
      end

      body do
        header do
          "<hgroup>"
            h1 do: "Micro"
            h3 do: "A Tiny Web Engine in Elixir"
            h5 do: "\"Just get the thing online...\""
          "</hgroup>"

          article do
            h2 do: "Some dynamic data for you:"
            code do
              "Micro Server Directory: #{get_page_dir()}"
            end

            code do
              "Page Map Size: #{map_size(get_page_map())}"
            end

            code do
              inspect(params())
            end

            for {k,v} <- System.build_info() do
              code do
                "#{k}: #{v}"
              end
            end
          end
        end
      end
    end
  end
end

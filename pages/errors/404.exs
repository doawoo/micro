defmodule Micro.Pages.Errors.NotFound do
  use Micro.Page

  page do
    html do
      body do
        h1 do: "404 - Page Not Found"
      end
    end
  end
end

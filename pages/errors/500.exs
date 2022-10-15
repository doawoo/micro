defmodule Micro.Pages.Errors.InternalServerError do
  use Micro.Page

  page do
    html do
      body do
        h1 do: "500 - Whoops!"
      end
    end
  end
end

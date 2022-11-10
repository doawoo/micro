defmodule Micro.GenericError do
  use Micro.Page

  page do
    html do
      "Micro.GenericError :: #{Process.get(:error_code)}"
    end
  end
end

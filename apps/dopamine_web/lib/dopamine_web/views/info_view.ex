defmodule DopamineWeb.InfoView do
  use DopamineWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  def render("client_versions.json", _assigns) do
      %{versions: ["r0.3.0"]}
  end

  def render("server_version.json", _assigns) do
    %{name: "Dopamine", version: to_string Application.spec(:dopamine_web, :vsn)}
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
end

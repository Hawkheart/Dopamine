defmodule DopamineWeb.MatrixErrorController do
  use Phoenix.Controller

  def call(conn, {:error, errcode}, status \\ nil, msg \\ nil) do
    status = if is_nil(status), do: get_status_code(errcode), else: status
    msg = if is_nil(msg), do: get_error_message(errcode), else: msg
    conn
    |> put_status(status)
    |> json(%{errcode: get_error_code(errcode), msg: msg})
  end

  defp get_error_message(err) do
    case err do
      :forbidden -> "You do not have permission to access this resource."
      :bad_token -> "The access token submitted was not valid."
      :no_token -> "This resource requires an access token."
      :user_used -> "A user by this name already exists."
      _ -> IO.inspect err; "An unknown error occured."
    end
  end

  defp get_error_code(err) do
    case err do
      :forbidden -> "M_FORBIDDEN"
      :bad_token -> "M_UNKNOWN_TOKEN"
      :no_token  -> "M_MISSING_TOKEN"
      :user_used -> "M_USER_IN_USE"
      _ -> "ART.HAWKHE.UNKNOWN"
    end
  end

  defp get_status_code(err) do
    case err do
      :forbidden -> 401
      :bad_token -> 401
      :no_token -> 401
      :user_used -> 400
      _ -> 500
    end
  end
end

defmodule ScoutApm.Plugs.ControllerTimer do
  alias ScoutApm.Internal.Layer

  def init(default), do: default

  def call(conn, _default) do
    ScoutApm.TrackedRequest.start_layer("Controller", action_name(conn))

    conn
    |> Plug.Conn.register_before_send(&before_send/1)
  end

  def before_send(conn) do
    full_name = action_name(conn)
    uri = "#{conn.scheme}://#{conn.host}#{conn.request_path}"

    ScoutApm.TrackedRequest.stop_layer(
      full_name,
      fn layer ->
        layer
        |> Layer.update_uri(uri)
      end
    )

    conn
  end

  # Takes a connection, extracts the phoenix controller & action, then manipulates & cleans it up.
  # Returns a string like "PageController#index"
  defp action_name(conn) do
    controller_name = conn.private[:phoenix_controller]
    action_name = conn.private[:phoenix_action]

    "#{controller_name}##{action_name}" # a string like "Elixir.TestappPhoenix.PageController#index"
      |>  String.split(".") # Split into a list
      |>  Enum.drop(2) # drop "Elixir.TestappPhoenix", leaving just ["PageController#index"]
      |>  Enum.join(".") # Probably just "joining" a 1 elem array, but recombine this way anyway in case of periods
  end

end

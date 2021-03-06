defmodule Phoenix.LiveView.Controller do
  @moduledoc """
  The Controller for LiveView rendering.
  """

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @doc """
  Renders a live view from a Plug request and sends an HTML response.

  Before render the `@live_view_module` assign will be added to the
  connection assigns for reference.

  ## Options

  See `Phoenix.LiveView.live_render/3` for all supported options.

  ## Examples

      defmodule ThermostatController do
        ...
        import Phoenix.LiveView.Controller

        def show(conn, %{"id" => thermostat_id}) do
          live_render(conn, ThermostatLive, session: %{
            thermostat_id: id,
            current_user_id: get_session(conn, :user_id),
          })
        end
      end

  """
  def live_render(%Plug.Conn{} = conn, view, opts \\ []) do
    case LiveView.Static.render(conn, view, opts) do
      {:ok, content} ->
        conn
        |> Plug.Conn.assign(:live_view_module, view)
        |> Phoenix.Controller.put_view(LiveView.Static)
        |> LiveView.Plug.put_cache_headers()
        |> Phoenix.Controller.render("template.html", %{content: content})

      {:stop, %Socket{redirected: {:redirect, opts}} = socket} ->
        conn
        |> put_flash(LiveView.Utils.get_flash(socket))
        |> Phoenix.Controller.redirect(to: Map.fetch!(opts, :to))

      {:stop, %Socket{redirected: {:live, opts}}} ->
        Phoenix.Controller.redirect(conn, to: Map.fetch!(opts, :to))
    end
  end

  defp put_flash(conn, nil), do: conn

  defp put_flash(conn, flash),
    do: Enum.reduce(flash, conn, fn {k, v}, acc -> Phoenix.Controller.put_flash(acc, k, v) end)
end

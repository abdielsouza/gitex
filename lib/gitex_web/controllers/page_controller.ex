defmodule GitexWeb.PageController do
  use GitexWeb, :controller

  def home(conn, _params) do
    conn
    |> redirect(to: ~p"/dashboard")
  end
end

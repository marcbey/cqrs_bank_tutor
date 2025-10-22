defmodule CqrsBankTutorWeb.PageController do
  use CqrsBankTutorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

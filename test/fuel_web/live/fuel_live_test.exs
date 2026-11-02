defmodule FuelWeb.FuelLiveTest do
  use FuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp add_steps(view, n) do
    for _ <- 1..n, do: view |> element("button", "Add step") |> render_click()
  end

  test "calculates total fuel for the Apollo 11 mission", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    add_steps(view, 4)

    steps =
      [launch: "earth", land: "moon", launch: "moon", land: "earth"]
      |> Enum.with_index()
      |> Map.new(fn {{action, planet}, i} -> {"#{i}", %{action: action, planet: planet}} end)

    view |> form("#flight", mass: "28801", steps: steps) |> render_change()

    assert has_element?(view, "#total", "51898 kg")
  end

  test "rejects a path not starting with launch, removing the step fixes it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    add_steps(view, 2)

    view
    |> form("#flight",
      mass: "28801",
      steps: %{
        "0" => %{action: "land", planet: "earth"},
        "1" => %{action: "launch", planet: "earth"}
      }
    )
    |> render_change()

    assert has_element?(view, "#path-error")
    assert has_element?(view, "#total", "—")

    view |> element("button[phx-value-index='0']") |> render_click()

    refute has_element?(view, "#path-error")
    assert has_element?(view, "#total", "19772 kg")
  end

  test "rejects non-positive mass", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    html = view |> form("#flight", mass: "-5") |> render_change()

    assert html =~ "must be a positive number"
    assert has_element?(view, "#total", "—")
  end
end

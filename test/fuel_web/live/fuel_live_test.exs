defmodule FuelWeb.FuelLiveTest do
  use FuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp change_mass(view, mass), do: render_hook(view, "change", %{"mass" => mass})

  defp add_steps(view, n) do
    Enum.each(1..n, fn _ -> view |> element("button", "Add step") |> render_click() end)
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

    assert has_element?(view, "select[aria-label='Step 1 action']")
    assert has_element?(view, "select[aria-label='Step 2 planet']")

    view |> element("button[aria-label='Remove step 1']") |> render_click()

    refute has_element?(view, "#path-error")
    assert has_element?(view, "#total", "19772 kg")
  end

  test "accepts empty, tiny and maximum mass", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    refute change_mass(view, "") =~ "must be"
    assert has_element?(view, "#total", "—")

    refute change_mass(view, "0.001") =~ "must be"
    assert has_element?(view, "#total", "0 kg")

    refute change_mass(view, "1000000000") =~ "must be"
    assert has_element?(view, "#total", "0 kg")
  end

  test "rejects non-positive and non-numeric mass", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert change_mass(view, "0") =~ "must be a positive number"
    assert change_mass(view, "-5") =~ "must be a positive number"
    assert change_mass(view, "abc") =~ "must be a positive number"
    assert change_mass(view, "1e2abc") =~ "must be a positive number"
    assert change_mass(view, "nan") =~ "must be a positive number"
    assert change_mass(view, "inf") =~ "must be a positive number"
    assert has_element?(view, "#total", "—")
  end

  test "rejects mass above the limit", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    add_steps(view, 1)

    html =
      view
      |> form("#flight", mass: "1e308", steps: %{"0" => %{action: "launch", planet: "earth"}})
      |> render_change()

    assert html =~ "must be at most 1000000000"
    assert has_element?(view, "#total", "—")

    assert change_mass(view, "1000000000.5") =~ "must be at most 1000000000"
  end

  test "caps steps and calculates the worst case at both limits", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    steps =
      Map.new(0..100, fn i ->
        {"#{i}",
         %{"action" => if(rem(i, 2) == 0, do: "launch", else: "land"), "planet" => "earth"}}
      end)

    render_hook(view, "change", %{"mass" => "1000000000", "steps" => steps})
    render_hook(view, "add", %{})

    assert has_element?(view, "button[phx-value-index='99']")
    refute has_element?(view, "button[phx-value-index='100']")
    assert has_element?(view, "button[phx-click='add'][disabled]")
    refute has_element?(view, "#total", "—")
  end

  test "survives malformed event payloads", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    rows = fn -> length(Regex.scan(~r/aria-label="Step \d+ action"/, render(view))) end

    # Non-string mass is treated as empty; a non-map step and non-string fields become blank steps.
    html =
      render_hook(view, "change", %{
        "mass" => 5,
        "steps" => %{"x" => 1, "0" => "bad", "1" => %{"action" => 1, "planet" => "earth"}}
      })

    refute html =~ "must be"
    assert rows.() == 2
    assert has_element?(view, "#path-error", "Choose an action and a planet")

    render_hook(view, "remove", %{"index" => "-1"})
    render_hook(view, "remove", %{"index" => "5"})
    render_hook(view, "remove", %{"index" => "abc"})
    render_hook(view, "remove", %{"index" => 0})
    render_hook(view, "remove", %{})
    assert rows.() == 2

    render_hook(view, "unknown", %{"anything" => [1, 2]})
    render_hook(view, "change", %{"steps" => [1, 2]})

    assert rows.() == 0
    assert has_element?(view, "#total", "—")
  end
end

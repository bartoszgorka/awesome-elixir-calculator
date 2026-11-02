defmodule FuelWeb.FuelLive do
  @moduledoc """
  Flight path builder: spacecraft mass plus launch/land steps,
  with the total fuel recalculated on every change.
  """
  use FuelWeb, :live_view

  alias Fuel.Calculator

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(mass: "", steps: []) |> calculate()}
  end

  @impl true
  def handle_event("change", params, socket) do
    steps =
      params
      |> Map.get("steps", %{})
      |> Enum.sort_by(fn {index, _} -> String.to_integer(index) end)
      |> Enum.map(fn {_, step} -> step end)

    {:noreply, socket |> assign(mass: params["mass"], steps: steps) |> calculate()}
  end

  def handle_event("add", _params, socket) do
    steps = socket.assigns.steps ++ [%{"action" => "", "planet" => ""}]
    {:noreply, socket |> assign(steps: steps) |> calculate()}
  end

  def handle_event("remove", %{"index" => index}, socket) do
    steps = List.delete_at(socket.assigns.steps, String.to_integer(index))
    {:noreply, socket |> assign(steps: steps) |> calculate()}
  end

  defp calculate(socket) do
    %{mass: mass, steps: steps} = socket.assigns
    path = Enum.map(steps, &parse_step/1)

    path_error =
      cond do
        !Enum.all?(path) ->
          "Choose an action and a planet for every step"

        !Calculator.valid_path?(path) ->
          "Flight must start with a launch, alternate launch and land, and launch from the planet it landed on"

        true ->
          nil
      end

    mass =
      case Float.parse(mass) do
        {mass, ""} when mass > 0 -> mass
        _ -> nil
      end

    assign(socket,
      mass_errors:
        if(mass || socket.assigns.mass == "", do: [], else: ["must be a positive number"]),
      path_error: path_error,
      fuel: mass && !path_error && Calculator.total_fuel(mass, path)
    )
  end

  defp parse_step(%{"action" => action, "planet" => planet}) do
    action = Enum.find(Calculator.actions(), &(Atom.to_string(&1) == action))
    planet = Enum.find(Calculator.planets(), &(Atom.to_string(&1) == planet))
    action && planet && {action, planet}
  end

  defp options(values), do: Enum.map(values, &{&1 |> Atom.to_string() |> String.capitalize(), &1})

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Interplanetary fuel calculator</.header>

      <form id="flight" phx-change="change" phx-submit="change">
        <.input
          name="mass"
          type="number"
          label="Spacecraft mass (kg)"
          value={@mass}
          errors={@mass_errors}
          min="0"
          step="any"
        />

        <div :for={{step, i} <- Enum.with_index(@steps)} class="flex gap-2 items-center">
          <span class="w-6">{i + 1}.</span>
          <.input
            type="select"
            name={"steps[#{i}][action]"}
            value={step["action"]}
            options={options(Calculator.actions())}
            prompt="Action"
          />
          <.input
            type="select"
            name={"steps[#{i}][planet]"}
            value={step["planet"]}
            options={options(Calculator.planets())}
            prompt="Planet"
          />
          <.button type="button" phx-click="remove" phx-value-index={i} aria-label="Remove step">
            <.icon name="hero-trash" />
          </.button>
        </div>

        <p :if={@path_error} id="path-error" class="text-error text-sm">{@path_error}</p>
        <.button type="button" phx-click="add" class="mt-2">Add step</.button>
      </form>

      <p id="total" class="mt-8 text-2xl font-semibold">
        Total fuel: {if @fuel, do: "#{@fuel} kg", else: "—"}
      </p>
    </Layouts.app>
    """
  end
end

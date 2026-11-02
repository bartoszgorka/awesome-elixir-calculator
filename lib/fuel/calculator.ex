defmodule Fuel.Calculator do
  @moduledoc """
  Fuel needed for a flight path, including the fuel needed to carry that fuel.
  """

  @gravity %{earth: 9.807, moon: 1.62, mars: 3.711}

  @type action :: :launch | :land
  @type planet :: :earth | :moon | :mars
  @type step :: {action(), planet()}
  @type path :: list(step())

  @doc "Supported planets."
  @spec planets() :: list(planet())
  def planets, do: Map.keys(@gravity)

  @doc "Supported flight actions."
  @spec actions() :: list(action())
  def actions, do: [:launch, :land]

  @doc """
  A path must start with a launch and alternate launch and land.
  Every launch after the first one must be from the planet the ship last landed on.
  """
  @spec valid_path?(path()) :: boolean()
  def valid_path?(path), do: valid_path?(path, :anywhere)

  defp valid_path?([], _at), do: true

  defp valid_path?([{:launch, planet} | rest], at) when at in [:anywhere, planet],
    do: valid_path?(rest, :in_flight)

  defp valid_path?([{:land, planet} | rest], :in_flight), do: valid_path?(rest, planet)
  defp valid_path?(_path, _at), do: false

  @doc """
  Total fuel for `path`, a list of `{action, planet}` steps.

  Walks the path backwards: every step also has to lift the fuel for all later steps.
  """
  @spec total_fuel(number(), path()) :: non_neg_integer()
  def total_fuel(mass, path) do
    path
    |> Enum.reverse()
    |> Enum.reduce(0, fn {action, planet}, fuel -> fuel + fuel(mass + fuel, action, planet) end)
  end

  @doc "Fuel for a single step, including fuel for the fuel."
  @spec fuel(number(), action(), planet()) :: non_neg_integer()
  def fuel(mass, action, planet) do
    case base_fuel(mass, action, @gravity[planet]) do
      fuel when fuel > 0 -> fuel + fuel(fuel, action, planet)
      _ -> 0
    end
  end

  defp base_fuel(mass, :launch, gravity), do: floor(mass * gravity * 0.042 - 33)
  defp base_fuel(mass, :land, gravity), do: floor(mass * gravity * 0.033 - 42)
end

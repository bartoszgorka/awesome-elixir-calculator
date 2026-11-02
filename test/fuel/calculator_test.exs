defmodule Fuel.CalculatorTest do
  use ExUnit.Case, async: true

  alias Fuel.Calculator

  test "mass too small to need fuel" do
    assert Calculator.fuel(1, :land, :moon) == 0
  end

  test "path must start with launch and alternate launch and land" do
    assert Calculator.valid_path?([])
    assert Calculator.valid_path?(launch: :earth, land: :moon, launch: :moon)
    refute Calculator.valid_path?(land: :earth)
    refute Calculator.valid_path?(launch: :earth, launch: :moon)
    refute Calculator.valid_path?(launch: :earth, land: :moon, land: :earth)
  end

  test "launch must be from the planet the ship landed on" do
    assert Calculator.valid_path?(launch: :earth, land: :mars, launch: :mars, land: :earth)
    refute Calculator.valid_path?(launch: :earth, land: :mars, launch: :moon)
  end

  test "empty path needs no fuel" do
    assert Calculator.total_fuel(28801, []) == 0
  end

  test "fuel calculations" do
    assert Calculator.fuel(28801, :land, :earth) == 13447
    assert Calculator.fuel(9278, :land, :earth) == 2960 + 915 + 254 + 40
    assert Calculator.fuel(2960, :land, :earth) == 915 + 254 + 40
    assert Calculator.fuel(915, :land, :earth) == 254 + 40
    assert Calculator.fuel(254, :land, :earth) == 40
    assert Calculator.fuel(40, :land, :earth) == 0
  end

  test "Apollo 11" do
    assert Calculator.total_fuel(28801, launch: :earth, land: :moon, launch: :moon, land: :earth) ==
             51898
  end

  test "Mars" do
    assert Calculator.total_fuel(14606, launch: :earth, land: :mars, launch: :mars, land: :earth) ==
             33388
  end

  test "Passenger ship" do
    assert Calculator.total_fuel(75432,
             launch: :earth,
             land: :moon,
             launch: :moon,
             land: :mars,
             launch: :mars,
             land: :earth
           ) == 212_161
  end
end

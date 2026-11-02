# Fuel

Interplanetary fuel calculator built with Elixir, Phoenix 1.8 and LiveView.

Enter the spacecraft mass, build a flight path out of `launch` / `land` steps,
and the required fuel is recalculated on every change.

## Running

Requires Elixir 1.20 / OTP 28 (see `.tool-versions`).

```sh
mix setup        # deps + assets
mix phx.server   # http://localhost:4000
mix test
```

## Structure

| File | Responsibility |
|---|---|
| `lib/fuel/calculator.ex` | Fuel formulas, planet gravities, flight path rules. Pure functions, no Phoenix. |
| `lib/fuel_web/live/fuel_live.ex` | The UI: parses and validates form input, calls the calculator. |
| `test/fuel/calculator_test.exs` | Formulas, the step-by-step example and the three example missions. |
| `test/fuel_web/live/fuel_live_test.exs` | End-to-end LiveView flows: Apollo 11 via the form, validation, removing a step. |

## How the calculation works

- **One step** (`Calculator.fuel/3`): apply the launch or landing formula (rounded down),
  then repeat it for the fuel just added, until the result is 0 or negative.
- **Whole path** (`Calculator.total_fuel/2`): the ship carries fuel for every later step,
  so the path is walked backwards. Each step is calculated for
  `mass + fuel needed by all later steps`.

| Mission | Mass | Fuel |
|---|---|---|
| Apollo 11 | 28 801 kg | 51 898 kg |
| Mars | 14 606 kg | 33 388 kg |
| Passenger ship | 75 432 kg | 212 161 kg |

## Validation

- Mass must be a positive number (decimals allowed).
- Every step needs an action and a planet. Values are checked against
  the calculator's whitelist, and user input is never turned into atoms.
- The path must start with a launch and alternate launch → land → launch …
- Every launch after the first one must be from the planet the ship last landed on.

While any input is invalid, the total shows "—" next to an error message.

## Decisions and assumptions

- No database, as the brief allows. State lives in the LiveView process.
- Validation lives in the calculator (`valid_path?/1`) and the LiveView, without Ecto changesets.
  For a single form with a dynamic list this needs less code.
- Not enforced, because the brief doesn't require it: ending the path with a landing.

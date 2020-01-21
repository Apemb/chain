# Chain

A library that mimics the JavaScript Promise API, but only as a synchronous way to organise code. 

## Installation

Chain is [available in Hex](https://hex.pm/chain), the package can be installed
by adding `chain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chain, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chain](https://hexdocs.pm/chain).

## Usage

A Chain is a list of steps to run sequentially.
Each next step gets the previous result as parameter and if returns `{:ok, value}` or `value` then `value` goes to the 
next next step in line. If it returns a `{:error, reason}` tuple, then `reason` goes to the next recover step in line.

There are three types of steps: 
- next: step that gets the previous result as parameter.
- recover: step that gets the previous error as parameter.
- capture: step that gets any raised error in the previous steps. 
    (if arity 1, gets the error, if arity 2, gets the error and the stacktrace)
    
```elixir
chain_result =
  initial_value
  |> Chain.new()
  |> Chain.next(&do_some_work/1)
  |> Chain.next(&do_some_more_work/1)
  |> Chain.recover(&recover_some_error/1)
  |> Chain.next(&do_some_other_work/1)
  |> Chain.capture(&manage_unexpected_runtime_errors/2)
  |> Chain.run()
```

## License

Licensed under the MIT License. See [License file](/LICENSE.md).

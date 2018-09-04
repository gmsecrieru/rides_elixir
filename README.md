# RidesElixir

A proof-of-concept Elixir application which performs a few Geolocation operations.

## Execution
First make sure you have all dependencies:
```bash
# Fetch dependencies
$ mix deps.get
```

The easyest way to try it out is by running `iex -S mix`:
```
$ iex -S mix
Erlang/OTP 20 [erts-9.3] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir (1.6.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> RidesElixir.run()
:ok
```

This will perform two actions:

- Process `pairs.csv` file and create bounding boxes for each pair or coordinates (i.e. line 1 + line 2, line 2 + line 3, line 3 + line 4 etc.).
- Process `coordinates.csv` files and assign each of its coordinates to a a previously created bounding box. Unmatched coordinates are discarded.

After this processing you can interact with data using both `%RidesElixir.Geo.Point{}` and `%RidesElixir.Geo.Box{}` structs. For your convenience, run the following lines in `iex`:

```elixir
iex(2)> alias RidesElixir.Geo.Box
RidesElixir.Geo.Box
iex(3)> alias RidesElixir.Geo.Point
RidesElixir.Geo.Point
```

`%Point{}` is the representation of a lon/lat coordinate, while `%Box{}` is the representation of the bounding box of two `%Point{}`s. `%Box{}` also holds a list of `%Point{}`s which are within its boundaries.

## Operations
`%Box{}` has several operations for manipulating data. You can list previously processed boxes with `list/0`:
```elixir
iex(4)> Box.list()
[
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.756699999999999, lon: 120.99206},
      %RidesElixir.Geo.Point{lat: 14.75659, lon: 120.99287}
    ]
  },
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.756939999999998, lon: 120.99203999999999},
      %RidesElixir.Geo.Point{lat: 14.756699999999999, lon: 120.99206}
    ]
  },
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.757139999999998, lon: 120.99203999999999},
      %RidesElixir.Geo.Point{lat: 14.756939999999998, lon: 120.99207999999999}
    ]
  },
  ...
```

You can create a new Box with `new/1`, which receives a pair of `%Point{}` and calculates the upper-left and bottom-right coordinates of the bounding box:

```elixir
iex(5)> Box.new([%Point{lon: 120, lat: 14}, %Point{lon: 121, lat: 15}])
%RidesElixir.Geo.Box{
  list: #MapSet<[]>,
  pair: [
    %RidesElixir.Geo.Point{lat: 15, lon: 120},
    %RidesElixir.Geo.Point{lat: 14, lon: 121}
  ]
}

```

Please note that `new/1` only creates the structure of a `%Box{}` and does not persist it locally. If you want to do so, use `put/1`:
```elixir
iex(6)> Box.new([%Point{lon: 120, lat: 14}, %Point{lon: 121, lat: 15}]) |> Box.put()
:ok
```

You can search for the first matching box of a given `%Point{}` using `find/1`, which returns a tuple with the index of the Box and the `%Box{}` struct itself:
```elixir
iex(7)> Box.find(%Point{lon: 120, lat: 14})
{327,
 %RidesElixir.Geo.Box{
   list: #MapSet<[]>,
   pair: [
     %RidesElixir.Geo.Point{lat: 15, lon: 120},
     %RidesElixir.Geo.Point{lat: 14, lon: 121}
   ]
 }}
```

You can also use `find/1` to look for a specific `%Box{}`:
```elixir
iex(8)> [%Point{lon: 120.99844000000004, lat: 14.65445}, %Point{lon: 120.99775000000004, lat: 14.65323}] |> Box.new() |> Box.find()
{101,
 %RidesElixir.Geo.Box{
   list: #MapSet<[]>,
   pair: [
     %RidesElixir.Geo.Point{lat: 14.65445, lon: 120.99775000000004},
     %RidesElixir.Geo.Point{lat: 14.65323, lon: 120.99844000000004}
   ]
 }}
```

Assign a particular `%Point{}` to the first matching box with `find_and_assign/1`. It leverages `MapSet` to make sure that no duplicates will occur -- trying to add a duplicated `%Point{}` is a `no-op`:
```elixir
iex(10)> %Point{lon: 120.9984, lat: 14.65445} |> Box.find_and_assign()
:ok
iex(12)> %Point{lon: 120.9984, lat: 14.65445} |> Box.find()
{101,
 %RidesElixir.Geo.Box{
   list: #MapSet<[%RidesElixir.Geo.Point{lat: 14.65445, lon: 120.9984}]>,
   pair: [
     %RidesElixir.Geo.Point{lat: 14.65445, lon: 120.99775000000004},
     %RidesElixir.Geo.Point{lat: 14.65323, lon: 120.99844000000004}
   ]
 }}
```

`filter/1` retrieves every `%Box{}` that matches a given `%Point{}`:
```elixir
iex(13)> %Point{lat: 14.65445, lon: 120.99775000000004} |> Box.filter()
[
  %RidesElixir.Geo.Box{
    list: #MapSet<[%RidesElixir.Geo.Point{lat: 14.65445, lon: 120.9984}]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.65445, lon: 120.99775000000004},
      %RidesElixir.Geo.Point{lat: 14.65323, lon: 120.99844000000004}
    ]
  },
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 15, lon: 120},
      %RidesElixir.Geo.Point{lat: 14, lon: 121}
    ]
  }
]
```

Finally, `find_and_put/1` receives a pair of `%Point{}` and retrieves a Keyword list with matching boxes for each one of them (i.e. origin and destination). It also creates the bounding box for the received pair if it does not exist already:
```elixir
iex(14)> [%Point{lon: 121.0111, lat: 14.787}, %Point{lon: 120.9853, lat: 14.6097}] |> Box.find_and_put()
[
  origin: [
    %RidesElixir.Geo.Box{
      list: #MapSet<[]>,
      pair: [
        %RidesElixir.Geo.Point{lat: 14.787, lon: 120.9853},
        %RidesElixir.Geo.Point{lat: 14.6097, lon: 121.0111}
      ]
    }
  ],
  destination: [
    %RidesElixir.Geo.Box{
      list: #MapSet<[]>,
      pair: [
        %RidesElixir.Geo.Point{lat: 15, lon: 120},
        %RidesElixir.Geo.Point{lat: 14, lon: 121}
      ]
    },
    %RidesElixir.Geo.Box{
      list: #MapSet<[]>,
      pair: [
        %RidesElixir.Geo.Point{lat: 14.787, lon: 120.9853},
        %RidesElixir.Geo.Point{lat: 14.6097, lon: 121.0111}
      ]
    }
  ]
]
```

Your can call `find_and_put/2` with `:origin` or `:destination` to receive only the matching boxes of the first or second `%Point{}` respectively:
```elixir
iex(15)> [%Point{lon: 121.0111, lat: 14.787}, %Point{lon: 120.9853, lat: 14.6097}] |> Box.find_and_put(:origin)
[
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.787, lon: 120.9853},
      %RidesElixir.Geo.Point{lat: 14.6097, lon: 121.0111}
    ]
  }
]
iex(16)> [%Point{lon: 121.0111, lat: 14.787}, %Point{lon: 120.9853, lat: 14.6097}] |> Box.find_and_put(:destination)
[
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 15, lon: 120},
      %RidesElixir.Geo.Point{lat: 14, lon: 121}
    ]
  },
  %RidesElixir.Geo.Box{
    list: #MapSet<[]>,
    pair: [
      %RidesElixir.Geo.Point{lat: 14.787, lon: 120.9853},
      %RidesElixir.Geo.Point{lat: 14.6097, lon: 121.0111}
    ]
  }
]
```

## Tests & static analysis
Run `mix test` to run the test suite:
```bash
$ mix test
..................

Finished in 0.3 seconds
18 tests, 0 failures

Randomized with seed 67962
```

Run `mix credo` for static code analysis:
```bash
$ mix credo
Checking 8 source files ...

Please report incorrect results: https://github.com/rrrene/credo/issues

Analysis took 0.5 seconds (0.02s to load, 0.4s running checks)
25 mods/funs, found no issues.

Use `--strict` to show all issues, `--help` for options.
```


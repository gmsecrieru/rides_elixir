defmodule RidesElixir.Geo.Box do
  @moduledoc """
  List, find, create and persist bounding boxes
  """

  alias RidesElixir.Geo.Point
  alias RidesElixir.Geo.Box

  @doc """
  Pair: List of points which delimit the bounding box: [upper_left, bottom_right]
  List: Points within this particular Box
  """
  defstruct pair: [], list: %MapSet{}

  @doc """
  List all persisted boxes
  """
  def list, do: Application.get_env(:rides_elixir, :bounding_boxes, [])

  @doc """
  Persist a bounding box to the list
  """
  def put(%Box{} = box), do: put(list() ++ [box])

  @doc """
  Persist a list of boxes
  """
  def put(box_list) when is_list(box_list),
    do: Application.put_env(:rides_elixir, :bounding_boxes, box_list)

  @doc """
  Creates a bounding box from a pair of coordinates, indexed as a
  list with two maps:
    - Upper-left Point of the bounding box
    - Bottom-right Point of the bounding box
  """
  def new([%Point{} = first, %Point{} = last]) do
    [min_lat, max_lat] = Enum.sort([first.lat, last.lat])
    [min_lon, max_lon] = Enum.sort([first.lon, last.lon])

    %Box{
      pair: [
        %Point{lon: min_lon, lat: max_lat},
        %Point{lon: max_lon, lat: min_lat}
      ]
    }
  end

  @doc """
  Find the matching bounding box of a given Point. Returns a tuple with
  the box index and the box itself, or nil if no matching box is found.
  """
  def find(%Point{lon: lon, lat: lat}) do
    valid_lat = fn %Box{pair: [%Point{lat: top_lat}, %Point{lat: bottom_lat}]} ->
      lat <= top_lat && lat >= bottom_lat
    end

    valid_lon = fn %Box{pair: [%Point{lon: top_lon}, %Point{lon: bottom_lon}]} ->
      lon >= top_lon && lon <= bottom_lon
    end

    index =
      list()
      |> Enum.find_index(fn box -> valid_lat.(box) && valid_lon.(box) end)

    case index do
      nil ->
        nil

      _ ->
        {index, Enum.at(list(), index)}
    end
  end

  @doc """
  Find an exact bounding box and return a tuple with its index and %Box{} struct
  or nil if no matching box is found
  """
  def find(%Box{pair: input_pair_list}) do
    index =
      list()
      |> Enum.find_index(fn %Box{pair: pair_list} -> pair_list == input_pair_list end)

    case index do
      nil ->
        nil

      _ ->
        {index, Enum.at(list(), index)}
    end
  end

  @doc """
  Find the matching bounding box of a given Point and assign it to the Box struct.
  Return nil if no matching box is found.
  """
  def find_and_assign(%Point{} = point) do
    case find(point) do
      {index, box} ->
        # assign point to box's point list -- MapSet in charge of ignoring duplicates
        mutated_box = update_in(box, [Access.key!(:list)], &MapSet.put(&1, point))

        # update box list with mutated box
        list()
        |> List.replace_at(index, mutated_box)
        |> put()

      _ ->
        nil
    end
  end

  @doc """
  Filters all matching boxes for a given Point. Returns a list of %Box{} or
  and empty list if no matching box is found
  """
  def filter(%Point{lon: lon, lat: lat}) do
    valid_lat = fn %Box{pair: [%Point{lat: top_lat}, %Point{lat: bottom_lat}]} ->
      lat <= top_lat && lat >= bottom_lat
    end

    valid_lon = fn %Box{pair: [%Point{lon: top_lon}, %Point{lon: bottom_lon}]} ->
      lon >= top_lon && lon <= bottom_lon
    end

    list()
    |> Enum.filter(fn box -> valid_lat.(box) && valid_lon.(box) end)
  end

  @doc """
  Find matching boxes and persist box for given pair. Returns a list
  with matching boxes for either origin or destination
  """
  def find_and_put(pair_list, only_boxes_for) when is_atom(only_boxes_for) do
    pair_list
    |> find_and_put()
    |> Keyword.get(only_boxes_for)
  end

  @doc """
  Find matching boxes and persist box for given pair. Returns a keyword list
  with matching boxes for origin and destination
  """
  def find_and_put([%Point{}, %Point{}] = pair_list) do
      # create bounding box for the pair provided
      pair_box = new(pair_list)
      unless Box.find(pair_box) do
        put(pair_box)
      end

      [origin, destination] =
        pair_list
        |> Enum.map(&filter/1)

      [origin: origin, destination: destination]
  end
end

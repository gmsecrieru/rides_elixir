defmodule RidesElixir.Data.Source do
  @moduledoc """
  Wrapper for data manipulation:
  - Loading process for both pairs.csv and coordinates.csv
    - This module assumes that both files are one level above Mix project directory (i.e. "rides_elixir" folder)

  - Persistance of bounding boxes
  - Assignment of coordinates to matching box

  For simplicity's sake, the persistance of data is done using Mix.Config
  """

  alias NimbleCSV.RFC4180, as: CSV

  alias RidesElixir.Geo.Box
  alias RidesElixir.Geo.Point

  @doc """
  Initializes data structures by:
  - Loading and parsing both CSV files
  - Persisting data to :rides_elixir Application config
  """
  def start do
    load_pairs()
    |> create_boxes_stream()
    |> Enum.to_list()
    |> Box.put()

    load_coordinates()
    |> assign_to_box()
  end

  @doc """
  Parses an input CSV stream of lon/lat into %Point{} structs
  """
  def parse_input_stream(stream) do
    stream
    |> CSV.parse_stream()
    |> Stream.map(fn [lon, lat] ->
      %Point{lon: String.to_float(lon), lat: String.to_float(lat)}
    end)
  end

  @doc """
  Parses a stream of %Point{} structs into a stream of bounding boxes
  """
  def create_boxes_stream(point_stream) do
    point_stream
    # avoid chunking last item if odd-sized input
    |> Stream.chunk_every(2, 1, :discard)
    |> Stream.map(&Box.new/1)
  end

  @doc """
  Maps through a %Point{} stream and assign to a bounding box. Discard %Point{}
  if no matching boxes are found
  """
  def assign_to_box(point_stream) do
    point_stream
    |> Stream.map(fn %Point{} = point -> Box.find_and_assign(point) end)
    |> Stream.run()
  end

  # Loads and parses pairs.csv file
  defp load_pairs, do: load_csv("pairs.csv")

  # Loads and parses coordinates.csv file
  defp load_coordinates, do: load_csv("coordinates.csv")

  # Creates a parsed stream from a given CSV path
  defp load_csv(relative_path) do
    relative_path
    |> Path.expand()
    |> File.stream!()
    |> parse_input_stream()
  end
end

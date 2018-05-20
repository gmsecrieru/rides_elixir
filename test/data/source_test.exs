defmodule RidesElixir.Data.SourceTest do
  use ExUnit.Case

  alias RidesElixir.Data.Source

  alias RidesElixir.Geo.Box
  alias RidesElixir.Geo.Point

  setup do
    # create a CSV-compatible mock stream
    {:ok, stream} =
      "lon,lat\n10.13212,20.245345\n30.364,40.48768\n50.549587345,60.623131\n"
      |> StringIO.open()

    mock_input_stream = IO.binstream(stream, :line)
    point_stream = Source.parse_input_stream(mock_input_stream)

    [mock_input_stream: mock_input_stream, point_stream: point_stream]
  end

  describe "parse_input_stream/1" do
    test "parses a stream of lon/lat pairs into a stream of %Point{}", context do
      stream_parsed_to_list_of_points =
        context[:point_stream]
        |> Enum.to_list()
        |> Enum.all?(fn
          (%Point{}) -> true
          (_) -> false
        end)

      assert stream_parsed_to_list_of_points
    end
  end

  describe "create_boxes_stream/1" do
    test "parses a stream of %Point{} into a stream of %Box{}", context do
      stream_parsed_to_list_of_boxes =
        context[:point_stream]
        |> Source.create_boxes_stream()
        |> Enum.to_list()
        |> Enum.all?(fn
          (%Box{}) -> true
          (_) -> false
        end)

      assert stream_parsed_to_list_of_boxes
    end
  end

  describe "assign_to_box/1" do

    # create a mock box in which every lon/lat pair from the mock stream fits in
    setup do
      %Box{pair: [%Point{lon: 10, lat: 61}, %Point{lon: 51, lat: 20}]}
      |> Box.put()
    end

    test "assigns %Point{} into a %Box{}", context do
      Source.assign_to_box(context[:point_stream])

      %Box{list: %MapSet{} = box_point_list} =
        Box.list()
        |> Enum.at(0)

      assert MapSet.size(box_point_list) == 3
    end
  end
end


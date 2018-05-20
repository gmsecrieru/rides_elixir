defmodule RidesElixir.Geo.BoxTest do
  use ExUnit.Case

  alias RidesElixir.Geo.Point
  alias RidesElixir.Geo.Box

  # clear test data prior to every test execution
  setup do
    on_exit(fn -> Box.put([]) end)
  end

  describe "put/1" do
    @tag box: %Box{pair: [%Point{lon: 1, lat: 10}, %Point{lon: 10, lat: 1}]}
    test "persists a single bounding box to a list", %{box: box} do
      Box.put(box)
      assert Box.list() == [box]
    end

    @tag box_list: [
      %Box{pair: [%Point{lon: 10, lat: 90}, %Point{lon: 100, lat: 10}]},
      %Box{pair: [%Point{lon: 20, lat: 80}, %Point{lon: 80, lat: 20}]}
    ]
    test "persists a list of bounding boxes", %{box_list: box_list} do
      Box.put(box_list)
      assert Box.list() == box_list
    end
  end

  describe "new/1" do
    # upper-left / bottom-right points of the bounding box
    @tag expected_box: %Box{pair: [%Point{lon: 33, lat: 90}, %Point{lon: 88, lat: 44}]}
    test "calculates bounding box based on coordinates pair", %{expected_box: expected_box} do
      # top-right
      first = %Point{lon: 88, lat: 90}
      # bottom-left
      second = %Point{lon: 33, lat: 44}

      assert Box.new([first, second]) == expected_box
    end
  end

  @moduletag box_list: [
    %Box{pair: [%Point{lon: 33, lat: 90}, %Point{lon: 45, lat: 85}]},
    %Box{pair: [%Point{lon: 50, lat: 80}, %Point{lon: 77, lat: 65}]}
  ]
  describe "find/1" do
    setup %{box_list: box_list} do
      Box.put(box_list)
    end

    @tag point: %Point{lon: 34, lat: 90}
    test "returns first bounding box found for a given point", %{point: point, box_list: [first_box | _]} do
      {_, box} = Box.find(point)

      assert box == first_box
    end

    @tag point: %Point{lon: 99, lat: 90}
    test "returns nil if no matching box found for a given point", %{point: point} do
      assert Box.find(point) == nil
    end

    test "returns exact match of a given box", %{box_list: [%Box{pair: mock_pair} = first_box | _]} do
      {_, %Box{pair: match_pair}} = Box.find(first_box)
      assert match_pair == mock_pair
    end

    test "returns nil if no exact match found for a given box" do
      refute Box.find(%Box{})
    end
  end

  @moduletag box_list: [
    %Box{pair: [%Point{lon: 33, lat: 80}, %Point{lon: 45, lat: 75}]},
    %Box{pair: [%Point{lon: 20, lat: 90}, %Point{lon: 77, lat: 65}]}
  ]
  describe "filter/1" do
    setup %{box_list: box_list} do
      Box.put(box_list)
    end

    test "returns all matching boxes of a given point" do
      length_of_matching_boxes =
        %Point{lon: 34, lat: 78}
        |> Box.filter()
        |> length()

      assert length_of_matching_boxes == 2
    end
  end

  @moduletag box_list: [
    %Box{pair: [%Point{lon: 33, lat: 90}, %Point{lon: 45, lat: 85}]},
    %Box{pair: [%Point{lon: 50, lat: 80}, %Point{lon: 77, lat: 65}]}
  ]
  describe "find_and_assign/1" do
    setup %{box_list: box_list} do
      Box.put(box_list)
    end

    @tag point: %Point{lon: 40, lat: 90}
    test "assigns Point to Box if a match exists", %{point: point} do
      :ok = Box.find_and_assign(point)
      {_, %Box{list: point_list}} = Box.find(point)

      assert Enum.at(point_list, 0) == point
    end

    @tag point: %Point{lon: 99, lat: 90}
    test "discards point if no matching box found", %{point: point} do
      assert Box.find_and_assign(point) == nil
    end
  end

  @moduletag box_list: [
    %Box{pair: [%Point{lon: 33, lat: 90}, %Point{lon: 45, lat: 85}]},
    %Box{pair: [%Point{lon: 50, lat: 80}, %Point{lon: 77, lat: 65}]}
  ]
  @moduletag point_list: [%Point{lon: 40, lat: 90}, %Point{lon: 51, lat: 70}]
  describe "find_and_put/1" do
    setup %{box_list: box_list} do
      Box.put(box_list)
    end

    test "creates a box for the provided pair of points", %{point_list: point_list} do
      assert length(Box.list()) == 2

      Box.find_and_put(point_list)

      assert length(Box.list()) == 3
    end

    test "returns matching boxes for a pair of points", %{point_list: point_list} do
      total_matching_boxes =
        point_list
        |> Box.find_and_put()
        # Keyword list with box list for origin/destination keys
        |> Enum.flat_map(fn {_, box_list} -> box_list end)
        |> MapSet.new()
        |> MapSet.size()

      assert total_matching_boxes == 3
    end

    test "returns matching boxes only for origin", %{point_list: point_list} do
      total_origin_matching_boxes =
        point_list
        |> Box.find_and_put(:origin)
        |> length()

      assert total_origin_matching_boxes == 2
    end

    test "returns matching boxes only for destination", %{point_list: point_list} do
      total_destination_matching_boxes =
        point_list
        |> Box.find_and_put(:destination)
        |> length()

      assert total_destination_matching_boxes == 2
    end
  end
end

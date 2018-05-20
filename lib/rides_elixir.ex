defmodule RidesElixir do
  @moduledoc """
  Main Application module
  """

  alias RidesElixir.Data.Source

  def run do
    # loads files and generates initial boxes
    Source.start()
  end
end

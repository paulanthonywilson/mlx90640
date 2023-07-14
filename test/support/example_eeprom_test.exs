defmodule ExampleEepromTest do
  use ExUnit.Case

  import ExampleEeprom

  test "substitute" do
    bytes = <<0, 1, 2, 3, 4, 5, 6, 7, 8>>

    assert bytes == substitute_raw_bytes(bytes, 0, <<>>)
    assert bytes == substitute_raw_bytes(bytes, 5, <<>>)
    assert <<255, 1, 2, 3, 4, 5, 6, 7, 8>> = substitute_raw_bytes(bytes, 0, <<255>>)
    assert <<255, 254, 2, 3, 4, 5, 6, 7, 8>> = substitute_raw_bytes(bytes, 0, <<255, 254>>)
    assert <<0, 255, 254, 3, 4, 5, 6, 7, 8>> == substitute_raw_bytes(bytes, 1, <<255, 254>>)
  end
end

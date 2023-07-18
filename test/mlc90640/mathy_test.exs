defmodule Mlc90640.MathyTest do
  use ExUnit.Case
  alias Mlc90640.Mathy

  test "maximum_doubling_while_less_than" do
    assert 0 == Mathy.maximum_doubling_while_less_than(1, 1)
    assert 1 == Mathy.maximum_doubling_while_less_than(1, 2)
    assert 2 == Mathy.maximum_doubling_while_less_than(1, 2.1)
    assert 2 == Mathy.maximum_doubling_while_less_than(1, 3)
    assert 2 == Mathy.maximum_doubling_while_less_than(1, 4)
    assert 3 == Mathy.maximum_doubling_while_less_than(1, 4.01)
    assert 11 = Mathy.maximum_doubling_while_less_than(29.233, 32_767.4)
  end

  test "max_abs" do
    assert 3 == Mathy.abs_max([1, 2, 3])
    assert 3 == Mathy.abs_max([1, 2, -3])
    assert nil == Mathy.abs_max([])
  end

  test "round_to_int" do
    assert 3 = Mathy.round_to_int(3.499)
    assert 3 = Mathy.round_to_int(2.5)
    assert -3 = Mathy.round_to_int(-2.5)
    assert -3 = Mathy.round_to_int(-3.499)
  end
end

defmodule Ref do
  @moduledoc false
  def ref(a \\ 0, b \\ 1, c \\ 2, d \\ 3) do
    :erlang.list_to_ref(~c"#Ref<#{a}.#{b}.#{c}.#{d}>")
  end
end

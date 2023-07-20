defmodule I2cCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  setup ctx do
    Mox.verify_on_exit!(ctx)
  end

  setup do
    {:ok, ref: Ref.ref()}
  end

  using do
    quote do
      import unquote(Ref)
    end
  end
end

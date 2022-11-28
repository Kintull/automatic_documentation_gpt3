defmodule AuDoc.MdBuilderTest do
  @moduledoc false
  use ExUnit.Case

  alias AuDoc.MdBuilder

  describe "build md from docs and filename" do
    test "converting docs to md" do
      documentation = %{"a" => "text1", "b" => "text2"}

      assert "# Module## a\ntext1\n\n## b\ntext2\n\n\n" ==
               MdBuilder.convert_docs_to_md("Module", documentation)
    end
  end
end

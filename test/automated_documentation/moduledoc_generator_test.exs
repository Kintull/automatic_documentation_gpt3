defmodule AuDoc.ModuledocGeneratorTest do
  @moduledoc false
  use ExUnit.Case

  alias AuDoc.ModuledocGenerator

  describe "updating db" do
    test "single file" do
      file_path = "./a/b/file.txt"
      db = %{}
      documentation = nil
      result = ModuledocGenerator.update_db_for_file(db, file_path, documentation)
      assert result == %{"." => %{"a" => %{"b" => %{"file.txt" => nil}}}}
    end

    test "two file in the same directory" do
      file_path = "./a/b/file.txt"
      file_path2 = "./a/b/file2.txt"
      db = %{}
      documentation = nil
      db = ModuledocGenerator.update_db_for_file(db, file_path, documentation)
      result = ModuledocGenerator.update_db_for_file(db, file_path2, documentation)
      assert result == %{"." => %{"a" => %{"b" => %{"file.txt" => nil, "file2.txt" => nil}}}}
    end
  end
end

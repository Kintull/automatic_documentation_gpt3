defmodule AuDoc.FlatDocBuilderTest do
  @moduledoc false
  use ExUnit.Case

  alias AuDoc.FlatDocBuilder
  alias AuDoc.FlatDoc

  describe "build flatdocs" do
    test "build simple flatdoc" do
      assert [
               %FlatDoc{
                 path: "./folder1",
                 name: "file.txt",
                 content: "File content",
                 path_with_name: "./folder1/file.txt",
                 type: :file
               }
             ] ==
               FlatDocBuilder.build(
                 {:file, "file.txt"},
                 %{"file.txt" => "File content"},
                 ["folder1", "."]
               )
    end

    test "build more complex flatdocs" do
      assert [
               %FlatDoc{path: "", name: ".", content: "", path_with_name: ".", type: :folder},
               %FlatDoc{
                 path: ".",
                 name: "folder1",
                 content: "",
                 path_with_name: "./folder1",
                 type: :folder
               },
               %FlatDoc{
                 path: "./folder1",
                 name: "file.ex",
                 content: "File content",
                 path_with_name: "./folder1/file.ex",
                 type: :file
               },
               %FlatDoc{
                 path: "./folder1",
                 name: "file2.ex",
                 content: "Another file content",
                 path_with_name: "./folder1/file2.ex",
                 type: :file
               }
             ] ==
               FlatDocBuilder.build(
                 ".",
                 %{
                   "." => %{
                     "folder1" => %{
                       "file.ex" => "File content",
                       "file2.ex" => "Another file content"
                     }
                   }
                 }
               )

      assert [
               %FlatDoc{path: ".", name: "folder1", content: ""},
               %FlatDoc{
                 path: "./folder1",
                 name: "file.txt",
                 content: "File content",
                 path_with_name: "./folder1/file.txt"
               }
             ] =
               FlatDocBuilder.build(
                 "folder1",
                 %{"folder1" => %{"file.txt" => "File content"}},
                 ["."]
               )
    end
  end
end

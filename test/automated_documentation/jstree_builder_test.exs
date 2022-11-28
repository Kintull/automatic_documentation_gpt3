defmodule AuDoc.JstreeBuilderTest do
  @moduledoc false
  use ExUnit.Case

  alias AuDoc.JstreeBuilder
  alias AuDoc.FlatDoc

  describe "building jstree structuress" do
    setup do
      flatdocs = [
        %FlatDoc{path: "", name: ".", content: "", path_with_name: ".", module_name: nil},
        %FlatDoc{
          path: ".",
          name: "folder1",
          content: "",
          path_with_name: "./folder1",
          module_name: nil
        },
        %FlatDoc{
          path: "./folder1",
          name: "file.ex",
          content: %{"Title" => "Documentation"},
          path_with_name: "./folder1/file.ex",
          module_name: "Module"
        },
        %FlatDoc{
          path: "./folder1",
          name: "file2.ex",
          content: %{"Title" => "Documentation"},
          path_with_name: "./folder1/file2.ex",
          module_name: "Module2"
        }
      ]

      [flatdocs: flatdocs]
    end

    test "build content lookup map for docs", %{flatdocs: flatdocs} do
      assert %{
               "." => "\n",
               ".-folder1" => "\n",
               ".-folder1-file.ex" => "# Module## Title\nDocumentation\n\n\n",
               ".-folder1-file2.ex" => "# Module2## Title\nDocumentation\n\n\n"
             } == JstreeBuilder.make_jstree_ojbects(flatdocs).lookup_map |> Jason.decode!()
    end

    test "build jstree structure", %{flatdocs: flatdocs} do
      assert %{
               "core" => %{
                 "data" => [
                   %{"id" => ".", "parent" => "#", "text" => "."},
                   %{"id" => ".-folder1", "parent" => ".", "text" => "folder1"},
                   %{"id" => ".-folder1-file.ex", "parent" => ".-folder1", "text" => "file.ex"},
                   %{"id" => ".-folder1-file2.ex", "parent" => ".-folder1", "text" => "file2.ex"}
                 ]
               }
             } == JstreeBuilder.make_jstree_ojbects(flatdocs).jstree |> Jason.decode!()
    end
  end
end

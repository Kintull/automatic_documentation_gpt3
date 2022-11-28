defmodule AuDoc.ModuleNamesStorage do
  @moduledoc false

  @db_path Application.compile_env(:au_doc, :generator_db_path)

  def build do
    root_path =
      "/Users/roman/work/system/apps/shedul-umbrella/apps/client_notifications/lib/client_notifications"

    db = File.read!(@db_path) |> Jason.decode!()

    File.cd(root_path)

    flatdocs = AuDoc.ModuledocGenerator.build_flatdocs(".", db)

    for flatdoc <- flatdocs do
      module_name =
        File.read!(flatdoc.path <> "/" <> flatdoc.name)
        |> String.split("\n")
        |> hd
        |> String.split(" ")
        |> Enum.at(1)

      {flatdoc.path <> "/" <> flatdoc.name, module_name}
    end
    |> Enum.into(%{})
    |> Jason.encode!()
    |> File.write!("/Users/roman/projects/automated_documentation/priv/module_names.json")
  end

  def read do
    File.read!("/Users/roman/projects/automated_documentation/priv/module_names.json")
    |> Jason.decode!()
  end
end

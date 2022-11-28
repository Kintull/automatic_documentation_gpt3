defmodule AuDoc.FlatDocBuilder do
  alias AuDoc.FlatDoc

  @doc """
   AuDoc.ModuledocGenerator.build_flatdocs(".", %{"." => %{"folder1" => %{"file.ex" => "File content", "file2.ex" => "Another file content"}}})
   AuDoc.ModuledocGenerator.build_flatdocs({:file, "file.txt"}, %{"file.txt" => "File content"}, ["folder1", "."])
   AuDoc.ModuledocGenerator.build_flatdocs("folder1", %{"folder1" => %{"file.txt" => "File content"}}, ["."])

  { "core" : { "data": [
    { "id" : ".", "parent" : "#", "text" : "."},
    { "id" : "folder1", "parent" : ".", "text" : "folder1" },
    { "id" : "file.txt", "parent" : "folder1", "text" : "file.txt" }
  ]}}

  """
  def build(node, tree, parent_folders \\ [])

  def build({:file, file}, tree, parent_folders) do
    [
      %FlatDoc{
        type: :file,
        path: build_path(parent_folders),
        name: file,
        content: tree[file],
        path_with_name: build_path_with_name(build_path(parent_folders), file)
      }
    ]
  end

  def build(current_folder, tree, parent_folders) do
    ([
       %FlatDoc{
         type: :folder,
         path: build_path(parent_folders),
         name: current_folder,
         content: "",
         path_with_name: build_path_with_name(build_path(parent_folders), current_folder)
       }
     ] ++
       for child_key <- Map.keys(tree[current_folder]) do
         if String.contains?(child_key, ".") do
           build({:file, child_key}, tree[current_folder], [
             current_folder | parent_folders
           ])
         else
           build(child_key, tree[current_folder], [
             current_folder | parent_folders
           ])
         end
       end)
    |> List.flatten()
  end

  defp build_path(reversed_parent_folders) do
    Enum.reverse(reversed_parent_folders)
    |> Enum.join("/")
  end

  defp build_path_with_name("", name), do: name
  defp build_path_with_name(path, name), do: path <> "/" <> name
end

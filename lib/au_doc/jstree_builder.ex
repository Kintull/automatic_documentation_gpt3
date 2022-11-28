defmodule AuDoc.JstreeBuilder do
  @moduledoc false

  @root_jstree_symbol "#"

  def make_jstree_ojbects(flatdocs) do
    data =
      for flatdoc <- flatdocs do
        parent = jstree_parent(flatdoc.path)
        id = jstree_id(flatdoc.path, flatdoc.name)
        text = flatdoc.name

        %{id: id, parent: parent, text: text}
      end

    %{
      jstree: %{core: %{data: data}} |> Jason.encode!(),
      lookup_map: jstree_documentation_lookup_map(flatdocs) |> Jason.encode!()
    }
  end

  def jstree_documentation_lookup_map(flatdocs) do
    Enum.into(flatdocs, %{}, fn flatdoc ->
      content = AuDoc.MdBuilder.convert_docs_to_md(flatdoc.module_name, flatdoc.content)

      {jstree_id(flatdoc.path, flatdoc.name), content}
    end)
  end

  defp jstree_id("", name), do: name
  defp jstree_id(path, name), do: jstree_parent(path) <> "-" <> name

  defp jstree_parent(""), do: @root_jstree_symbol
  defp jstree_parent(path), do: path |> String.replace("/", "-")
end

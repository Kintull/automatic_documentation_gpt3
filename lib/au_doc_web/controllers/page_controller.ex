defmodule AuDocWeb.PageController do
  use AuDocWeb, :controller

  alias AuDoc.FlatDocBuilder
  alias AuDoc.JstreeBuilder

  def index(conn, _params) do
    flatdocs =
      FlatDocBuilder.build(".", %{
        "." => %{
          "folder1" => %{"file.ex" => "File content", "file2.ex" => "Another file content"}
        }
      })

    %{jstree: jstree, lookup_map: lookup_map} = JstreeBuilder.make_jstree_ojbects(flatdocs)

    render(conn, "index.html", %{jstree: jstree, lookup_map: lookup_map})
  end
end

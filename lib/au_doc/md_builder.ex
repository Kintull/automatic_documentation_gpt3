defmodule AuDoc.MdBuilder do
  @moduledoc false

  def convert_docs_to_md(_, ""), do: "\n"
  def convert_docs_to_md(nil, _), do: "\n"

  def convert_docs_to_md(module_name, %{} = documentation) do
    documentation_keys = Map.keys(documentation)

    paragraphs =
      for key <- documentation_keys do
        "## #{key}\n#{documentation[key]}\n\n"
      end

    "# #{module_name}" <> Enum.join(paragraphs) <> "\n"
  end
end

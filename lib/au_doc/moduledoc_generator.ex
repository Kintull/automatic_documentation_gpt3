defmodule AuDoc.ModuledocGenerator do
  @moduledoc """
  Write what is the responsibility of this module.
  Write what problem this module solves.
  Write important notions from this module

  Write down a full list of the module dependencies
  Write down all the functional requirements of the module.
  Write a detailed description of all the public functions in this module.

  TODO:
    * for template files like *.*eex - either skip them of find a good prompt, now it produces a mess.
    * think of classification of existing answers by quality
    * think of editing existing answers to a given format
  """

  @max_model_tokens 3800
  @sleep_delay Application.compile_env(:au_doc, :generator_sleep_delay_ms)
  @temperature Application.compile_env(:au_doc, :generator_temperature)
  @min_tokens_as_output Application.compile_env(:au_doc, :generator_min_tokens_as_output)
  @db_path Application.compile_env(:au_doc, :generator_db_path)
  @processed_files_path Application.compile_env(:au_doc, :generator_processed_files_path)

  alias AuDoc.FlatDoc

  def process_all_files() do
    db = read_storage()

    all_files = load_file_list()

    processed_files = read_processed_files()
    len_all_files = length(all_files)

    Enum.reduce(Enum.with_index(all_files), db, fn {file_path, index}, db ->
      IO.inspect("Processing #{index}/#{len_all_files}..")

      if file_path in processed_files do
        db
      else
        case generate_for_file(file_path) do
          {:ok, doc_map} ->
            db = update_db_for_file(db, file_path, doc_map)
            update_storage(db)
            update_processed_files(file_path)
            db

          {:error, _} ->
            db
        end
      end
    end)
  end

  defp load_file_list() do
    root_research_path =
      "/Users/roman/work/system/apps/shedul-umbrella/apps/client_notifications/lib/client_notifications"

    read_all_files_with_path(root_research_path)
  end

  defp read_processed_files() do
    binary = File.read!(@processed_files_path)
    String.split(binary)
  end

  defp update_processed_files(file_path) do
    file = File.open!(@processed_files_path, [:append])
    IO.binwrite(file, String.to_charlist(file_path) ++ '\n')
  end

  def generate_for_file(file_path) do
    contents = File.read!(file_path)

    basic_instructions = [
      "Write what is the responsibility of this module (up to 200 symbols)."
    ]

    instructions = maybe_add_optional_instructions(basic_instructions, contents)

    content_tokens = Regex.split(~r/[ .,\nae]/, contents) |> length
    max_tokens = @max_model_tokens - content_tokens

    instruction_map =
      Enum.into(instructions, %{}, fn instruction ->
        res =
          if max_tokens > @min_tokens_as_output do
            result =
              AuDoc.Gpt3APIClient.complete_input(contents,
                max_tokens: max_tokens,
                temperature: @temperature,
                instruction: instruction
              )

            :timer.sleep(@sleep_delay)
            result
          else
            "Error: file is too big"
          end

        {instruction, res}
      end)

    if Enum.any?(Map.values(instruction_map), fn x -> String.starts_with?(x, "Error:") end) do
      {:error, :processing_failed}
    else
      {:ok, instruction_map}
    end
  end

  def read_storage() do
    case File.read(@db_path) do
      {:ok, ""} -> %{}
      {:ok, db} -> Jason.decode!(db)
      {:error, _} -> %{}
    end
  end

  defp update_storage(db) do
    content = Jason.encode!(db) |> Jason.Formatter.pretty_print()
    File.write!(@db_path, content)
  end

  defp read_all_files_with_path(base_path) do
    File.cd(base_path)

    :os.cmd('find . -type f -follow -print | grep -E ".ex$"')
    |> to_string()
    |> String.split()
  end

  def update_db_for_file(db, file_path, documentation) do
    chunks = String.split(file_path, ["/"], trim: true)
    path = Enum.slice(chunks, 0..-2)
    file_name = Enum.at(chunks, -1)

    value =
      case get_in(db, path) do
        nil ->
          %{file_name => documentation}

        map ->
          Map.put(map, file_name, documentation)
      end

    put_in(db, Enum.map(path, &Access.key(&1, %{})), value)
  end

  defp maybe_add_optional_instructions(basic_instructions, contents) do
    cond do
      String.contains?(contents, "use GenServer") ->
        basic_instructions ++
          detailed_description_instructions() ++
          [
            "Write down what triggers this GenServer, what is the routine that it is doing, what messages it listens to."
          ]

      String.contains?(contents, "use Ecto.Schema") ->
        basic_instructions ++
          ["Write down attributes that are persisted into database, what attributes are virtual."]

      String.contains?(contents, "defdelegate ") ->
        basic_instructions ++
          ["Write down a high level overview of all defdelegate in the module."]

      String.contains?(contents, "Kafkaesque") ->
        basic_instructions ++
          detailed_description_instructions() ++
          ["Write down kafka events that this modules consumes or produces."]

      true ->
        basic_instructions ++
          detailed_description_instructions()
    end
  end

  defp detailed_description_instructions do
    [
      "Write down what problem this module solves (up to 200 symbols).",
      "Write down important notions from this module."
    ]
  end

  @root_jstree_symbol "#"

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

  def build_flatdocs(node, tree, parent_folders \\ [])

  def build_flatdocs({:file, file}, tree, parent_folders) do
    [
      %FlatDoc{
        type: :file,
        path_with_name: build_path(parent_folders) <> "/" <> file,
        path: build_path(parent_folders),
        name: file,
        content: tree[file]
      }
    ]
  end

  def build_flatdocs(current_folder, tree, parent_folders) do
    ([
       %FlatDoc{
         path_with_name: build_path(parent_folders) <> "/" <> current_folder,
         path: build_path(parent_folders),
         name: current_folder,
         content: "",
         type: :folder
       }
     ] ++
       for child_key <- Map.keys(tree[current_folder]) do
         if String.contains?(child_key, ".") do
           build_flatdocs({:file, child_key}, tree[current_folder], [
             current_folder | parent_folders
           ])
         else
           build_flatdocs(child_key, tree[current_folder], [
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

  def make_jstree_ojbects(flatdocs) do
    data =
      for flatdoc <- flatdocs do
        parent = jstree_parent(flatdoc.path)
        id = jstree_id(flatdoc.path, flatdoc.name)
        text = flatdoc.name

        %{id: id, parent: parent, text: text}
      end

    %{
      jstree: %{core: %{data: data}} |> IO.inspect() |> Jason.encode!(),
      lookup_map: jstree_documentation_lookup_map(flatdocs) |> Jason.encode!()
    }
  end

  def jstree_documentation_lookup_map(flatdocs) do
    Enum.into(flatdocs, %{}, fn flatdoc ->
      {jstree_id(flatdoc.path, flatdoc.name), flatdoc.content}
    end)
  end

  defp jstree_id("", name), do: name
  defp jstree_id(path, name), do: jstree_parent(path) <> "-" <> name

  defp jstree_parent(""), do: @root_jstree_symbol
  defp jstree_parent(path), do: path |> String.replace("/", "-")

  #
  #    def make_jstree_structure({:file, file}, tree, parent_folder) do
  #      [%{id: path_to_file<>file, parent: parent_folder, text: tree[file]}]
  #    end
  #
  #    def make_jstree_structure(current_folder, tree, parent_folder) do
  #      [%{id: current_folder, parent: parent_folder, text: current_folder}] ++
  #        for child_key <- Map.keys(tree[current_folder]) do
  #          if String.ends_with?(child_key, ".ex") do
  #            make_jstree_structure({:file, child_key}, tree[current_folder], current_folder)
  #          else
  #            make_jstree_structure(child_key, tree[current_folder], current_folder)
  #          end
  #        end
  #        |> List.flatten()
  #    end
  #
  #    def make_jstree_core(current_folder, tree, parent_folder) do
  #      data = make_jstree_structure(current_folder, tree, parent_folder)
  #
  #      %{core: %{data: data}} |> Jason.encode!()
  #    end
  #
end

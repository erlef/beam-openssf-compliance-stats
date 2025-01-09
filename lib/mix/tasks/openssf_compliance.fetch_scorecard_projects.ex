# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.OpenssfCompliance.FetchScoreCardProjects do
  @shortdoc "Fetch all OpenSSF ScoreCard Projects"
  @moduledoc """
  #{@shortdoc}

  ## Arguments

  * Name of Dataset
  """

  use Mix.Task

  alias Explorer.DataFrame
  alias OpenSSFCompliance.ScoreCard

  require Explorer.DataFrame

  @requirements ["app.start"]

  @impl Mix.Task
  def run([dataset_name]) do
    in_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/projects")
      |> Path.join("#{dataset_name}.parquet")

    out_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/scorecard")
      |> Path.join("#{dataset_name}.parquet")

    with {:ok, relevant_projects} <- DataFrame.from_parquet(in_path),
         projects = load_projects(relevant_projects),
         :ok <- DataFrame.to_parquet(projects, out_path) do
      # REUSE-IgnoreStart
      File.write!("#{out_path}.license", """
      SPDX-FileCopyrightText: 2015-#{Date.utc_today().year} OpenSSF ScoreCard
      SPDX-License-Identifier: CDLA-Permissive-2.0
      """)

      # REUSE-IgnoreEnd

      Mix.shell().info("Wrote #{DataFrame.n_rows(projects)} projects to #{inspect(out_path)}")
    else
      error ->
        Mix.raise("Failed to fetch projects, Error: #{inspect(error, pretty: true)}")
    end
  end

  defp load_projects(relevant_projects) do
    relevant_projects
    |> DataFrame.drop_nil([:platform, :owner, :repository])
    |> DataFrame.select([:platform, :owner, :repository])
    |> DataFrame.distinct()
    |> DataFrame.to_rows_stream()
    |> Stream.map(
      &%{
        platform: String.to_existing_atom(&1["platform"]),
        owner: &1["owner"],
        repository: &1["repository"]
      }
    )
    |> ScoreCard.load_projects()
    |> Enum.map(&%{&1 | platform: Atom.to_string(&1.platform)})
    |> DataFrame.new(
      dtypes: [
        {"platform", :category},
        {"score", {:f, 32}}
      ]
    )
  end
end

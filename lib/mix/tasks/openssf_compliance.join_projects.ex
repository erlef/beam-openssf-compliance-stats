# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.OpenssfCompliance.JoinProjects do
  @shortdoc "Join Project Data"
  @moduledoc """
  #{@shortdoc}

  ## Arguments

  * Name of Dataset
  """

  use Mix.Task

  alias Explorer.DataFrame

  require Explorer.DataFrame

  @requirements ["app.start"]

  @impl Mix.Task
  def run([dataset_name]) do
    project_in_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/projects")
      |> Path.join("#{dataset_name}.parquet")

    badge_in_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/badge")
      |> Path.join("#{dataset_name}.parquet")

    scorecard_in_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/scorecard")
      |> Path.join("#{dataset_name}.parquet")

    out_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/joined")
      |> Path.join("#{dataset_name}.parquet")

    with {:ok, projects} <- DataFrame.from_parquet(project_in_path),
         {:ok, badges} <- DataFrame.from_parquet(badge_in_path),
         {:ok, scorecards} <- DataFrame.from_parquet(scorecard_in_path),
         joined = join_dataset(projects, badges, scorecards),
         {:ok, license_info} <- merge_license_info([project_in_path, badge_in_path, scorecard_in_path]),
         :ok <- DataFrame.to_parquet(joined, out_path),
         :ok <- File.write("#{out_path}.license", license_info) do
      Mix.shell().info("Wrote #{DataFrame.n_rows(joined)} projects to #{inspect(out_path)}")
    else
      error ->
        Mix.raise("Failed to fetch projects, Error: #{inspect(error, pretty: true)}")
    end
  end

  defp join_dataset(projects, badges, scorecards) do
    badges = DataFrame.rename(badges, name: :badge_name, id: :badge_id, tiered_percentage: :badge_tiered_percentage)

    scorecards = DataFrame.rename(scorecards, score: :scorecard_score)

    projects
    |> DataFrame.join(badges, how: :left)
    |> DataFrame.join(scorecards, how: :left)
  end

  defp merge_license_info(paths) do
    Enum.reduce_while(paths, {:ok, ""}, fn path, {:ok, acc} ->
      case File.read("#{path}.license") do
        {:ok, content} -> {:cont, {:ok, acc <> content}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end

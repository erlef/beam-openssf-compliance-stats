# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.OpenssfCompliance.FetchProjects do
  @shortdoc "Fetch all Hex Repositories"
  @moduledoc """
  #{@shortdoc}

  ## Arguments

  * Name of Dataset
  """

  use Mix.Task

  alias Explorer.DataFrame
  alias Explorer.Series
  alias OpenSSFCompliance.Hex

  require Explorer.DataFrame

  @requirements ["app.start"]

  @impl Mix.Task
  def run([dataset_name]) do
    out_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/projects")
      |> Path.join("#{dataset_name}.parquet")

    with {:ok, projects} <- read_projects(),
         :ok <- DataFrame.to_parquet(projects, out_path) do
      # REUSE-IgnoreStart
      File.write!("#{out_path}.license", """
      SPDX-FileCopyrightText: 2014-#{Date.utc_today().year} Hex.pm Package Manager
      SPDX-License-Identifier: CC-BY-3.0
      """)

      # REUSE-IgnoreEnd

      Mix.shell().info("Wrote #{DataFrame.n_rows(projects)} projects to #{inspect(out_path)}")
    else
      error -> Mix.raise("Failed to fetch packages, Error: #{inspect(error, pretty: true)}")
    end
  end

  defp read_projects do
    with {:ok, packages} <- Hex.load_packages(),
         {:ok, additional_projects} <- read_additional_projects() do
      {:ok,
       packages
       |> Enum.map(&Map.merge(&1, %{type: "package", platform: platform_to_string(&1.platform)}))
       |> Explorer.DataFrame.new()
       |> DataFrame.concat_rows(additional_projects)
       |> DataFrame.mutate(
         platform: Series.cast(platform, :category),
         type: Series.cast(type, :category)
       )}
    end
  end

  defp read_additional_projects do
    additional_projects_path =
      Application.app_dir(:openssf_compliance, "priv/additional_projects.tsv")

    with {:ok, additional_projects} <-
           DataFrame.from_csv(additional_projects_path, delimiter: "\t") do
      {:ok,
       DataFrame.put(
         additional_projects,
         :total_downloads,
         Series.from_list([nil], dtype: {:u, 64})
       )}
    end
  end

  defp platform_to_string(platform)
  defp platform_to_string(nil), do: nil
  defp platform_to_string(platform), do: Atom.to_string(platform)
end

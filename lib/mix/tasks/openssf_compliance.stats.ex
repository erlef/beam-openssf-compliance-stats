# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.OpenssfCompliance.Stats do
  @shortdoc "Output Statistics for fetched Data"
  @moduledoc """
  #{@shortdoc}

  ## Arguments

  * Name of Dataset
  """

  use Mix.Task

  alias Explorer.DataFrame
  alias Explorer.Series

  require Explorer.DataFrame

  @requirements ["app.start"]

  @impl Mix.Task
  def run([dataset_name]) do
    in_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/joined")
      |> Path.join("#{dataset_name}.parquet")

    case DataFrame.from_parquet(in_path) do
      {:ok, projects} ->
        print_global_stats(projects)
        print_badge_stats(projects)
        print_scorecard_stats(projects)

      error ->
        Mix.raise("Failed to fetch projects, Error: #{inspect(error, pretty: true)}")
    end
  end

  defp print_global_stats(projects) do
    project_count = DataFrame.n_rows(projects)

    project_count_mult = 100 / project_count

    pltform_table =
      projects
      |> DataFrame.group_by(:platform)
      |> DataFrame.summarise(count: Series.count(name), percentage: ^project_count_mult * Series.count(name))
      |> dump_table()

    Mix.shell().info("""
    # Hex.pm Packages

    `#{project_count}` Projects

    #{pltform_table}
    """)
  end

  defp print_badge_stats(projects) do
    project_count = DataFrame.n_rows(projects)

    projects_with_badges = DataFrame.drop_nil(projects, :badge_tiered_percentage)

    n_with_badges = DataFrame.n_rows(projects_with_badges)

    arithmetic_mean_percentage = Series.mean(projects_with_badges[:badge_tiered_percentage])
    median_percentage = Series.median(projects_with_badges[:badge_tiered_percentage])
    stdev = Series.standard_deviation(projects_with_badges[:badge_tiered_percentage])

    project_count_mult = 100 / project_count

    badge_level_table =
      projects_with_badges
      |> DataFrame.group_by(:badge_level)
      |> DataFrame.summarise(count: Series.count(name), percentage: ^project_count_mult * Series.count(name))
      |> dump_table()

    Mix.shell().info("""
    # Badge

    `#{n_with_badges}` out of `#{project_count}` projects have a badge (`#{inspect(100 / project_count * n_with_badges)}%`)

    Tiered Percentage:
    * Mean `#{inspect(arithmetic_mean_percentage)}`
    * Median `#{inspect(median_percentage)}`
    * Standard Deviation `#{inspect(stdev)}`

    #{badge_level_table}
    """)
  end

  defp print_scorecard_stats(projects) do
    project_count = DataFrame.n_rows(projects)

    projects_with_scorecards = DataFrame.drop_nil(projects, :scorecard_score)

    n_with_scorecards = DataFrame.n_rows(projects_with_scorecards)

    arithmetic_mean_percentage = Series.mean(projects_with_scorecards[:scorecard_score])
    median_percentage = Series.median(projects_with_scorecards[:scorecard_score])
    stdev = Series.standard_deviation(projects_with_scorecards[:scorecard_score])

    Mix.shell().info("""
    # ScoreCard

    `#{n_with_scorecards}` out of `#{project_count}` projects have a scorecard (`#{inspect(100 / project_count * n_with_scorecards)}%`)

    Score:
    * Mean `#{inspect(arithmetic_mean_percentage)}`
    * Median `#{inspect(median_percentage)}`
    * Standard Deviation `#{inspect(stdev)}`
    """)
  end

  defp dump_table(dataframe) do
    data = [
      List.duplicate("-", length(dataframe.names))
      | dataframe
        |> DataFrame.to_rows()
        |> Enum.map(fn row ->
          Enum.map(dataframe.names, &row[&1])
        end)
    ]

    data
    |> TableRex.Table.new(dataframe.names)
    # TODO: Replace Custom Print Function with `gfm` style once the following
    # PR is released:
    # https://github.com/djm/table_rex/pull/59
    |> TableRex.Table.render!(
      intersection_symbol: "|",
      header_separator_symbol: "-",
      horizontal_style: :off
    )
    |> String.replace(~r/^\|\s+\|\n/m, "")
  end
end

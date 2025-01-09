# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.OpenssfCompliance.FetchBadgeProjects do
  @shortdoc "Fetch all OpenSSF Badges"
  @moduledoc """
  #{@shortdoc}

  ## Arguments

  * Name of Dataset
  """

  use Mix.Task

  alias Explorer.DataFrame
  alias OpenSSFCompliance.Badge

  require Explorer.DataFrame

  @requirements ["app.start"]

  @impl Mix.Task
  def run([dataset_name]) do
    out_path =
      :openssf_compliance
      |> Application.app_dir("priv/data/badge")
      |> Path.join("#{dataset_name}.parquet")

    projects = load_projects()

    case DataFrame.to_parquet(projects, out_path) do
      :ok ->
        # REUSE-IgnoreStart
        File.write!("#{out_path}.license", """
        SPDX-FileCopyrightText: 2015-#{Date.utc_today().year} OpenSSF Best Practices Badge
        SPDX-License-Identifier: CC-BY-3.0 AND CDLA-Permissive-2.0
        """)

        # REUSE-IgnoreEnd

        Mix.shell().info("Wrote #{DataFrame.n_rows(projects)} projects to #{inspect(out_path)}")

      error ->
        Mix.raise("Failed to fetch projects, Error: #{inspect(error, pretty: true)}")
    end
  end

  defp load_projects do
    Badge.load_projects()
    |> Enum.map(&%{&1 | platform: platform_to_string(&1.platform)})
    |> DataFrame.new(
      dtypes: [
        {"id", {:u, 64}},
        {"badge_level", :category},
        {"platform", :category},
        {"tiered_percentage", {:u, 64}}
      ]
    )
  end

  defp platform_to_string(platform)
  defp platform_to_string(nil), do: nil
  defp platform_to_string(platform), do: Atom.to_string(platform)
end

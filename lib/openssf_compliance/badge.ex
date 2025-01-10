# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance.Badge do
  @moduledoc false

  require Logger

  @type project() :: %{
          id: String.t(),
          name: String.t(),
          tiered_percentage: non_neg_integer(),
          badge_level: String.t(),
          platform: OpenSSFCompliance.platform() | nil,
          owner: String.t() | nil,
          repository: String.t() | nil,
          total_downloads: non_neg_integer()
        }

  @rate_limit_window to_timeout(minute: 1)
  @rate_limit_anonymous 100

  def load_projects do
    wait_timeout = ceil(@rate_limit_window / @rate_limit_anonymous)

    page_stream =
      wait_timeout
      |> Stream.interval()
      |> Stream.map(&(&1 + 1))

    OpenSSFCompliance.TaskSupervisor
    |> Task.Supervisor.async_stream(
      page_stream,
      &load_page/1,
      ordered: false,
      timeout: to_timeout(second: 30)
    )
    |> Stream.map(fn {:ok, response} -> response end)
    |> Stream.take_while(&match?(%Req.Response{body: [_ | _]}, &1))
    |> Stream.flat_map(& &1.body)
    |> Stream.map(&Map.take(&1, ~w[badge_level id name tiered_percentage repo_url]))
    |> Stream.map(fn
      %{
        "badge_level" => badge_level,
        "id" => id,
        "name" => name,
        "tiered_percentage" => tiered_percentage,
        "repo_url" => uri
      } ->
        repository =
          case OpenSSFCompliance.fetch_uri_repository(uri) do
            :error -> %{platform: nil, owner: nil, repository: nil}
            {:ok, repository} -> repository
          end

        Map.merge(repository, %{
          id: id,
          name: name,
          tiered_percentage: tiered_percentage,
          badge_level: badge_level
        })
    end)
    |> Stream.transform(1, fn package, acc ->
      if rem(acc, 100) == 0 do
        Logger.info("Fetched #{acc} packages")
      end

      {[package], acc + 1}
    end)
  end

  defp load_page(page) do
    Req.get!("https://www.bestpractices.dev/en/projects.json",
      params: [page: page],
      user_agent: "Beam OpenSSF Compliance Stats <https://github.com/erlef/beam-openssf-compliance-stats>"
    )
  end
end

# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance.ScoreCard do
  @moduledoc false

  require Logger

  @type input_project() :: %{
          platform: OpenSSFCompliance.platform(),
          owner: String.t(),
          repository: String.t()
        }

  @type project() :: %{
          platform: OpenSSFCompliance.platform(),
          owner: String.t(),
          repository: String.t(),
          score: float()
        }

  @rate_limit_window to_timeout(minute: 1)
  @rate_limit_anonymous 500

  @spec load_projects(projects :: Enumerable.t(input_project())) :: Enumerable.t(project())
  def load_projects(projects) do
    project_stream = throttle(projects)

    OpenSSFCompliance.TaskSupervisor
    |> Task.Supervisor.async_stream(
      project_stream,
      &load_project/1,
      ordered: false,
      timeout: to_timeout(second: 30)
    )
    |> Stream.map(fn {:ok, response} -> response end)
    |> Stream.transform(1, fn package, acc ->
      if rem(acc, 100) == 0 do
        Logger.info("Fetched #{acc} projects")
      end

      {[package], acc + 1}
    end)
    |> Stream.reject(&is_nil/1)
  end

  @platform_hosts %{
    github: "github.com",
    gitlab: "gitlab.com",
    bitbucket: "bitbucket.org"
  }

  defp load_project(search)

  defp load_project(%{platform: platform, owner: owner, repository: repository} = search) do
    platform = @platform_hosts[platform]

    "https://api.securityscorecards.dev/projects/#{platform}/#{owner}/#{repository}"
    |> Req.get!(user_agent: "Beam OpenSSF Compliance Stats <https://github.com/erlef/beam-openssf-compliance-stats>")
    |> case do
      %Req.Response{status: 200, body: %{"score" => score}} -> Map.put(search, :score, score)
      %Req.Response{status: 404} -> nil
    end
  end

  @spec throttle(stream :: Enumerable.t(t)) :: Enumerable.t(t) when t: term()
  defp throttle(stream) do
    Stream.map(stream, fn element ->
      Process.sleep(ceil(@rate_limit_window / @rate_limit_anonymous))
      element
    end)
  end
end

# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance.Hex do
  @moduledoc false

  require Logger

  @type package() :: %{
          name: String.t(),
          platform: :github | :gitlab | :bitbucket | nil,
          owner: String.t() | nil,
          repository: String.t() | nil,
          total_downloads: non_neg_integer()
        }

  @rate_limit_window to_timeout(minute: 1)
  @rate_limit_user 500
  @rate_limit_anonymous 100

  @spec load_packages() :: {:ok, Enumerable.t(package())} | {:error, term()}
  def load_packages do
    with {:ok, package_names} <- load_package_names() do
      load_all_package_details(package_names)
    end
  end

  @spec config() :: :hex_core.config()
  defp config do
    config = :hex_core.default_config()

    config =
      Map.put(
        config,
        :http_user_agent_fragment,
        "Beam OpenSSF Compliance Stats <https://github.com/erlef/beam-openssf-compliance-stats>"
      )

    case System.fetch_env("HEX_API_KEY") do
      :error -> config
      {:ok, key} -> Map.put(config, :api_key, key)
    end
  end

  @spec load_package_names() :: {:ok, Enumerable.t(String.t())} | {:error, term()}
  defp load_package_names do
    with {:ok, {200, _headers, %{packages: packages}}} <- :hex_repo.get_names(config()) do
      {:ok, Stream.map(packages, & &1.name)}
    end
  end

  @spec load_all_package_details(package_names :: Enumerable.t(String.t())) ::
          {:ok, Enumerable.t(package())} | {:error, term()}
  defp load_all_package_details(package_names) do
    OpenSSFCompliance.TaskSupervisor
    |> Task.Supervisor.async_stream(
      throttle(package_names),
      &load_package_details/1,
      ordered: false,
      max_concurrency: 5,
      timeout: to_timeout(second: 30)
    )
    |> Stream.transform(1, fn package, acc ->
      # if rem(acc, 100) == 0 do
      Logger.info("Fetched #{acc} packages")
      # end

      {[package], acc + 1}
    end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, {:ok, package}}, {:ok, acc} -> {:cont, {:ok, [package | acc]}}
      {:ok, {:error, reason}}, {:ok, _acc} -> {:halt, {:error, reason}}
      {:exit, reason}, {:ok, _acc} -> {:halt, {:error, {:exit, reason}}}
    end)
  end

  @spec load_package_details(package_name :: String.t()) :: {:ok, package()} | {:error, term()}
  defp load_package_details(package_name) do
    with {:ok, response} <- :hex_api_package.get(config(), package_name) do
      case response do
        {200, _headers,
         %{
           "meta" => %{"links" => links},
           "downloads" => %{"all" => total_downloads}
         }} ->
          package =
            Map.merge(
              %{name: package_name, total_downloads: total_downloads},
              find_package_repository(links, package_name)
            )

          {:ok, package}

        response ->
          {:error, {:invalid_response, response}}
      end
    end
  end

  @known_bad_hosts ["hex.pm", "hexdocs.pm"]
  @host_platform_mapping %{
    "github.com" => :github,
    "www.github.com" => :github,
    "gitlab.com" => :gitlab,
    "www.gitlab.com" => :gitlab,
    "bitbucket.org" => :bitbucket,
    "www.bitbucket.org" => :bitbucket
  }
  @knwon_good_hosts Map.keys(@host_platform_mapping)

  @spec find_package_repository(
          links :: %{optional(String.t()) => String.t()},
          package_name :: String.t()
        ) :: %{
          platform: :github | :gitlab | :other | nil,
          owner: String.t() | nil,
          repository: String.t() | nil
        }
  defp find_package_repository(links, package_name) do
    links = Map.new(links, fn {name, value} -> {String.downcase(name), value} end)

    priority_keys = ["github", "gitlab", "repository"]

    {urls, links} =
      Enum.reduce(priority_keys, {[], links}, fn key, {urls, links} ->
        case Map.pop(links, key) do
          {nil, links} -> {urls, links}
          {url, links} -> {[url | urls], links}
        end
      end)

    urls
    |> Enum.concat(Map.values(links))
    |> Enum.map(&URI.parse/1)
    |> Enum.find_value(%{platform: nil, owner: nil, repository: nil}, fn
      %URI{host: host, path: "/" <> path} when host in @knwon_good_hosts ->
        case String.split(path, "/", parts: 3) do
          [owner, repository | _rest] ->
            %{platform: @host_platform_mapping[host], owner: owner, repository: repository}

          _other ->
            false
        end

      %URI{host: host} when host in @known_bad_hosts ->
        false

      other ->
        Logger.warning("Unknown URI for package #{inspect(package_name)}: #{inspect(other)}")
        false
    end)
  end

  @spec throttle(stream :: Enumerable.t(t)) :: Enumerable.t(t) when t: term()
  defp throttle(stream) do
    limit =
      case config() do
        %{api_key: :undefined} -> @rate_limit_anonymous
        _other -> @rate_limit_user
      end

    Stream.map(stream, fn element ->
      Process.sleep(ceil(@rate_limit_window / limit))
      element
    end)
  end
end

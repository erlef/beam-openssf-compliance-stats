# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance do
  @moduledoc false

  @type platform() :: :github | :gitlab | :bitbucke

  @type repository() :: %{
          platform: platform(),
          owner: String.t(),
          repository: String.t()
        }

  @host_platform_mapping %{
    "github.com" => :github,
    "www.github.com" => :github,
    "gitlab.com" => :gitlab,
    "www.gitlab.com" => :gitlab,
    "bitbucket.org" => :bitbucket,
    "www.bitbucket.org" => :bitbucket
  }
  @knwon_good_hosts Map.keys(@host_platform_mapping)

  @spec fetch_uri_repository(url :: Strin.t() | URI.t()) :: {:ok, repository()} | :error
  def fetch_uri_repository(uri)
  def fetch_uri_repository(uri) when is_binary(uri), do: uri |> URI.parse() |> fetch_uri_repository()

  def fetch_uri_repository(%URI{host: host, path: "/" <> path}) when host in @knwon_good_hosts do
    case String.split(path, "/", parts: 3) do
      [owner, repository | _rest] ->
        {:ok, %{platform: @host_platform_mapping[host], owner: owner, repository: repository}}

      _other ->
        :error
    end
  end

  def fetch_uri_repository(%URI{}), do: :error
end

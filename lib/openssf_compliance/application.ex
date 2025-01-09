# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(
      [
        {Task.Supervisor, name: OpenSSFCompliance.TaskSupervisor}
      ],
      strategy: :one_for_one,
      name: OpenSSFCompliance.Supervisor
    )
  end
end

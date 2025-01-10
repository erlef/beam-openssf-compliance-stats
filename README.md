<!--
SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
SPDX-License-Identifier: Apache-2.0
-->

# BEAM OpenSSF Compliance Statistics

[![EEF Security WG project](https://img.shields.io/badge/EEF-Security-black)](https://github.com/erlef/security-wg)

Statistics Tool to collect OpenSSF compliance statistics for the BEAM ecosystem.

## Configuration

Some additional projects are considered besides Hex.pm packages. Those have to
be added to the `priv/additional_projects.tsv` file.

## Usage

```
┌──────────────────────────────────┐         ┌─────────────────────────────────────────────┐
│File: priv/additional_projects.tsv│         │$ mix openssf_compliance.fetch_badge_projects│
└─────────────────┬────────────────┘         └───────────────────┬─────────────────────────┘
                  │                                              │
┌─────────────────▼─────────────────────┐    ┌───────────────────▼────────────────┐
│$ mix openssf_compliance.fetch_projects│    │File: priv/data/badge/[NAME].parquet│
└─────────────────┬─────────────────────┘    └───────────────────┬────────────────┘
                  │                                              │
┌─────────────────▼─────────────────────┐                        │
│File: priv/data/projects/[NAME].parquet│                        │
└─────────────────┬─────────────────────┘                        │
                  │                                              |
┌─────────────────▼───────────────────────────────┐              |
│$ mix openssf_compliance.fetch_scorecard_projects│              |
└─────────────────┬───────────────────────────────┘              |
                  │                                              |
┌─────────────────▼──────────────────────┐                       |
│File: priv/data/scorecard/[NAME].parquet│                       |
└─────────────────┬──────────────────────┘                       |
                  │   ┌──────────────────────────────────────────┘
┌─────────────────▼───▼────────────────┐
│$ mix openssf_compliance.join_projects│
└─────────────────┬────────────────────┘
                  │
┌─────────────────▼───────────────────┐
│File: priv/data/joined/[NAME].parquet│
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼────────────┐
│$ mix openssf_compliance.stats│
└──────────────────────────────┘
```
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

## Automated Data Storage

This project automatically fetches new data once a month using the
[`.github/workflows/calculate_dataset.yml` action](./.github/workflows/calculate_dataset.yml)
and stores the datasets in git in the[`priv/data/joined` directory](./priv/data/joined).

You can see the recent runs [in the Actions Tab](/actions/workflows/calculate_dataset.yml).
Each run contains a summary of the new statistics and also offers the intermediate
files for download.

## License

The code in this repository is licensed under the `Apache-2.0` license.

Data produced by the contained commands, are licensed based on their origin. Check
the `[FILENAME].license` file next to each dataset to see its license.

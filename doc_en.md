# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

# PureBashCoverage
A pure, self-contained tool for evaluating test coverage of Bash scripts — without dependencies on other languages.

## Key Features

- Automatically tracks every executed line.
- Generates HTML reports: coverage percentage, line statistics, code display with highlighted executed lines.

## Usage

Add to the beginning of your script:

```
export PS4='+${BASH_SOURCE}:${LINENO}:'
set -x
```

Generate coverage report:

```
path/to/generate_coverage_report.sh path/to/script.sh
```


The coverage report will be generated in the directory from which the scripts generate_coverage_report.sh were launched.

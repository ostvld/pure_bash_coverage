#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT
# Argument check
if [ $# -ne 1 ]; then
    echo "Usage: $0 <bash-code.sh>"
    exit 1
fi

log_file="${PWD}/coverage.log"
script_file="$1"

${script_file} &> ${log_file}

# File check
if [ ! -f "$log_file" ] || [ ! -f "$script_file" ]; then
    echo "Error: One of the files was not found"
    exit 2
fi

# Get script basename
script_basename=$(basename "$script_file")
total_lines=$(wc -l < "$script_file")

# Generate HTML report
awk -v total_lines="$total_lines" -v script_basename="$script_basename" '
BEGIN {
    print "<!DOCTYPE html>"
    print "<html>"
    print "<head>"
    print "<title>Code Coverage Report</title>"
    print "<style>"
    print "body { font-family: monospace; }"
    print ".covered { background-color: #dfd; }"
    print ".not-covered { background-color: #fdd; }"
    print "pre { margin: 0; }"
    print ".line-number { color: #999; }"
    print ".line-content { padding-left: 10px; }"
    print "table { border-collapse: collapse; width: 100%; }"
    print "tr:hover { background-color: #f5f5f5; }"
    print "td { vertical-align: top; }"
    print "</style>"
    print "</head>"
    print "<body>"
    covered_count = 0
}

NR == FNR {
    # Process report.log - MODIFIED for format: ++./scripts/filename:linenumber:command
    # Look for lines that contain the filename with any path before it
    if (match($0, "^[+]+.*/" script_basename ":([0-9]+):", matches)) {
        line = matches[1]
        coverage[line] = 1
        covered_count++
    }
    next
}

FNR == 1 {
    percent_covered = (total_lines == 0) ? 100 : (covered_count * 100) / total_lines
    printf "<h1>Code Coverage Report for %s</h1>\n", script_basename
    printf "<p>Total lines: %d</p>\n", total_lines
    printf "<p>Covered lines: %d</p>\n", covered_count
    printf "<p>Coverage percentage: %.2f%%</p>\n", percent_covered
    print "<table>"
    print "<tr><th>Line</th><th>Count</th><th>Code</th></tr>"
}

{
    line_num = FNR
    count = coverage[line_num] ? coverage[line_num] : 0

    # HTML escaping
    code = $0
    gsub(/&/, "\\&amp;", code)
    gsub(/</, "\\&lt;", code)
    gsub(/>/, "\\&gt;", code)

    if (count > 0) {
        tr_class = "covered"
    } else {
        tr_class = "not-covered"
    }

    printf "<tr class=\"%s\">\n", tr_class
    printf "<td class=\"line-number\">%d</td>\n", line_num
    printf "<td class=\"count\">%d</td>\n", count
    printf "<td class=\"line-content\"><pre>%s</pre></td>\n", code
    print "</tr>"
}

END {
    print "</table>"
    print "</body>"
    print "</html>"
}
' "$log_file" "$script_file" > ${PWD}/coverage_report.html

echo "Report created: coverage_report.html"
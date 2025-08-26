#!/bin/bash

# Проверка аргументов
if [ $# -ne 2 ]; then
    echo "Использование: $0 <report.log> <bash-code.sh>"
    exit 1
fi

report_file="$1"
script_file="$2"

# Проверка файлов
if [ ! -f "$report_file" ] || [ ! -f "$script_file" ]; then
    echo "Ошибка: Один из файлов не найден"
    exit 2
fi

# Получаем базовое имя скрипта
script_basename=$(basename "$script_file")
total_lines=$(wc -l < "$script_file")

# Генерируем HTML отчет
awk -v total_lines="$total_lines" -v script_basename="$script_basename" '
BEGIN {
    print "<!DOCTYPE html>"
    print "<html>"
    print "<head>"
    print "<title>Отчет о покрытии кода</title>"
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
    # Обрабатываем report.log - ИЗМЕНЕНО для формата: ++./scripts/filename:linenumber:command
    # Ищем строки, которые содержат имя файла с любым путем перед ним
    if (match($0, "^[+]+.*/" script_basename ":([0-9]+):", matches)) {
        line = matches[1]
        coverage[line] = 1
        covered_count++
    }
    next
}

FNR == 1 {
    percent_covered = (total_lines == 0) ? 100 : (covered_count * 100) / total_lines
    printf "<h1>Отчет о покрытии кода для %s</h1>\n", script_basename
    printf "<p>Общее строк: %d</p>\n", total_lines
    printf "<p>Покрыто строк: %d</p>\n", covered_count
    printf "<p>Процент покрытия: %.2f%%</p>\n", percent_covered
    print "<table>"
    print "<tr><th>Строка</th><th>Счетчик</th><th>Код</th></tr>"
}

{
    line_num = FNR
    count = coverage[line_num] ? coverage[line_num] : 0

    # Экранирование HTML
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
' "$report_file" "$script_file" > coverage_report.html

echo "Отчет создан: coverage_report.html"

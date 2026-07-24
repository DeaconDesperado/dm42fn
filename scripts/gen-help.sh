#!/bin/sh
# Generate a DM42-compatible .htm help file from .hp42s source comments.
# Usage: gen-help.sh solar/solar.hp42s tenon/tenon.hp42s > help/dm42fnhelp.htm
#
# Extracts function documentation from @ comment blocks delimited by
# @ ---- lines. Ignores decorative @ ==== lines and file headers.
#
# DM42 help viewer supports a minimal HTML subset:
#   <h1>-<h4> <p> <b> <i> <code> <pre> <hr> <ul> <li> <table> <tr> <td>

cat <<'HEADER'
<h1>dm42fn &mdash; Function Library</h1>
<hr>
HEADER

for src in "$@"; do
    suite=$(basename "$(dirname "$src")")
    suite_emitted=0
    in_func=0
    func_started=0

    while IFS= read -r line; do
        line=$(printf '%s' "$line" | tr -d '\r')

        case "$line" in
            "@ ="*)
                ;;
            "@ -"*)
                if [ "$in_func" = 1 ]; then
                    if [ "$func_started" = 1 ]; then
                        echo "</pre>"
                        func_started=0
                    fi
                    in_func=0
                else
                    in_func=1
                fi
                ;;
            "@ "*)
                if [ "$in_func" = 1 ]; then
                    text="${line#@ }"
                    if [ "$func_started" = 0 ]; then
                        if [ "$suite_emitted" = 0 ]; then
                            echo "<h2>${suite}</h2>"
                            suite_emitted=1
                        fi
                        echo "<h3>${text}</h3>"
                        echo "<pre>"
                        func_started=1
                    else
                        echo "${text}"
                    fi
                fi
                ;;
            "LBL "*)
                if [ "$func_started" = 1 ]; then
                    echo "</pre>"
                    func_started=0
                fi
                in_func=0
                ;;
        esac
    done < "$src"

    if [ "$func_started" = 1 ]; then
        echo "</pre>"
    fi
    echo "<hr>"
done

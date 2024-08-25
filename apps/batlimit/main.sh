#!/bin/sh

# By default it switches between 60 and 100. Optionally you can indicate an specific limit.

THRESHOLD_FILE="/sys/class/power_supply/BAT1/charge_control_end_threshold"

batlimit() {
    new_limit=$1

    current_limit=$(cat "$THRESHOLD_FILE")

    if [ "$new_limit" = '' ]; then
        if [ "$current_limit" = '71' ]; then
            new_limit='100'
        else
            new_limit='71'
        fi
    fi

    sudo echo "$new_limit" | sudo tee "$THRESHOLD_FILE" >/dev/null
    if ! sudo -nv 2>/dev/null; then
        return 1
    fi

    printf "OLD THRESHOLD: %s\n" "$current_limit"
    printf "NEW THRESHOLD: %s\n" "$new_limit"
}

main() {
    if echo "$@" | grep --extended-regexp -- '(--help|-help|-h)' >/dev/null; then
        echo "batlimit [new-limit]"
        echo
        echo "Default behavior:"
        echo "  Switch the threshold between 60 and 100"
        echo
        echo "--help,-h Show this help message"
        exit 0
    fi

    new_limit="$1"

    if [ -n "$new_limit" ] && ! echo "$new_limit" | grep -Eq '^[1-9]|[1-9][0-9]|100$'; then
        printf '\033[31mEnter a number between 1 and 100.\033[0m\n'
        return 1
    fi

    batlimit "$@"
}

main "$@"

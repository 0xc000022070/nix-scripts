#!/bin/sh

PROGRAM_NAME="nmcli-wifi-scan-waybar"

print_waybar_json_output() {
    text="$1"
    tooltip="$2"
    class="$3"

    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
}

main() {
    should_scan=false

    if echo "$@" | grep -E '^--scan$' >/dev/null; then
        should_scan=true
    elif [ "$#" -gt 0 ]; then
        echo "Unknown arguments has been passed. Pass the --scan flag or don't pass anything." >&2
        return
    fi

    state_file="/tmp/.${PROGRAM_NAME}-running"

    if test -f "$state_file"; then
        if ! $should_scan; then
            print_waybar_json_output "󱛆" "Scanning wifi spots..." "scanning"
        fi

        return
    fi

    if $should_scan; then
        echo "yes" >"$state_file"
        nmcli radio wifi on && nmcli --fields SSID,SECURITY,BARS device wifi list ifname "$(nmcli device | awk '$2 == "wifi" {print $1}')" --rescan yes
        rm -f "$state_file"
        return
    fi

    print_waybar_json_output "󱛄" "Scan wifi networks nearby" "default"
}

main "$@"

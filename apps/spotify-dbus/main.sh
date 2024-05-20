#!/bin/sh

# https://www.reddit.com/r/i3wm/comments/2bhhog/mediakeys_spotify_for_noobs/

DESTINY="org.mpris.MediaPlayer2.spotify"
MESSAGE_PATH="/org/mpris/MediaPlayer2"

get_raw_position() {
    dbus-send --print-reply \
        --dest="$DESTINY" "/org/mpris/MediaPlayer2" \
        "org.freedesktop.DBus.Properties.Get" string:"org.mpris.MediaPlayer2.Player" string:"Position" |
        sort -r | head -n 1 | awk '{print $3}'
}

get_raw_track_id() {
    dbus-send --print-reply \
        --dest="$DESTINY" "/org/mpris/MediaPlayer2" \
        "org.freedesktop.DBus.Properties.Get" string:"org.mpris.MediaPlayer2.Player" string:"Metadata" |
        grep --after-context=1 'mpris:trackid' | sort -r | head -n 1 | awk -F'"' '{print $2}'
}

set_position() {
    new_position="$1"

    dbus-send --print-reply --dest="$DESTINY" /org/mpris/MediaPlayer2 \
        org.mpris.MediaPlayer2.Player.SetPosition "objpath:$(get_raw_track_id)" "int64:$new_position"
}

send_command_via_dbus() {
    name="$1"

    dbus-send --print-reply --dest="$DESTINY" "$MESSAGE_PATH" "org.mpris.MediaPlayer2.Player.$name"
}

PROGRAM_NAME="spotify-dbus"

main() {
    case "$1" in
    --next)
        send_command_via_dbus "Next"
        ;;
    --prev | --previous)
        send_command_via_dbus "Previous"
        ;;
    --toggle)
        send_command_via_dbus "PlayPause"
        ;;
    --stop)
        send_command_via_dbus "Stop"
        ;;
    --push-back)
        position=$(get_raw_position)

        x="1000000"
        new_position=$(node -e "console.log(($position / $x - 5) * $x)")

        set_position "$new_position"
        ;;

    --push-forward)
        position=$(get_raw_position)

        x="1000000"
        new_position=$(node -e "console.log(($position / $x + 5) * $x)")

        set_position "$new_position"
        ;;
    *)
        echo "Usage"
        echo "$PROGRAM_NAME [flag]"
        echo "Flags:"
        echo "--next               Send a dbus message to pass to the next song"
        echo "--prev | --previous  Send a dbus message to go to the previous song"
        echo "--toggle             Send a dbus message to play or pause the current song"
        echo "--push-back          Send a dbus message to go back 5 seconds"
        echo "--push-forward       Send a dbus message to go forward 5 seconds"
        echo "--stop               Send a dbus message to just stop"
        exit 1
        ;;
    esac
}

main "$@"

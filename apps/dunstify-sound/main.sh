#!/bin/sh

ASSETS_PATH="path/to/assets"

PROGRAM_NAME="dunstify-sound"
LEVEL_OFFSET=4

SOURCE_TAG="string:x-dunst-stack-tag:source"
SINK_TAG="string:x-dunst-stack-tag:sink"

BAR_COLOR="bar-color-placeholder"

print_usage_and_exit() {
    echo "Usage:"
    echo "$PROGRAM_NAME [flags]"
    echo
    echo "Required flags:"
    echo "  --inc		Increase speaker's volume."
    echo "  --dec		Decrease speaker's volume."
    echo "  --toggle-mic	Turn on/off speaker."
    echo "  --toggle-vol	Turn on/off microphone."
    echo
    echo "Optional flags:"
    echo "  --unleashed	Exceed to maximum value(if possible)"
    exit 1
}

main() {
    case "$1" in
    --inc)
        if [ "$2" = "--unleashed" ]; then
            pactl -- set-sink-volume 0 +$LEVEL_OFFSET%
        else
            amixer set Master $LEVEL_OFFSET%+
        fi

        notify_audio_update
        ;;
    --dec)
        amixer set Master $LEVEL_OFFSET%-
        notify_audio_update
        ;;
    --toggle-vol)
        amixer set Master toggle
        notify_audio_update
        ;;
    --toggle-mic)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        notify_microphone_update
        ;;
    --unleashed)
        if [ "$2" = "" ] || [ "$2" = "--unleashed" ]; then
            print_usage_and_exit
        fi

        main "$2" "$1"
        ;;
    *)
        print_usage_and_exit
        ;;
    esac
}

notify_audio_update() {
    vol_state=$(amixer sget Master | awk -F"[][]" '/Left:/ { print $4 }')
    vol_level=$(amixer sget Master | awk -F"[][]" '/Left:/ { print $2 }' | cut -d '%' -f 1)

    sink_icon_path=""

    if [ "$vol_state" = "off" ] || [ "$vol_level" = 0 ]; then
        sink_icon_path="$ASSETS_PATH/volume-off.512.png"
    else
        if [ "$vol_level" -lt 34 ]; then
            sink_icon_path="$ASSETS_PATH/volume-low.512.png"
        elif [ "$vol_level" -lt 67 ]; then
            sink_icon_path="$ASSETS_PATH/volume-medium.512.png"
        else
            sink_icon_path="$ASSETS_PATH/volume-high.512.png"
        fi
    fi

    dunstify -h "int:value:$vol_level" \
        -h "string:hlcolor:$BAR_COLOR" \
        -u low \
        -h "$SINK_TAG" \
        -i "$sink_icon_path" \
        "Volume:" \
        "$vol_level%"
}

notify_microphone_update() {
    notification_message=""
    source_icon_path=""

    if pactl list sources | grep -qi 'Mute: yes'; then
        source_icon_path="$ASSETS_PATH/mic-off.512.png"
        notification_message="Muted"
    else
        source_icon_path="$ASSETS_PATH/mic-on.512.png"
        notification_message="Unmuted"
    fi

    dunstify -u low \
        -h $SOURCE_TAG \
        -i "$source_icon_path" \
        "Microphone" \
        "$notification_message"
}

main "$@"

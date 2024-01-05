
clean:
    set +e
    rm -rf result _build
    find . -type d -name 'target' -exec rm -rf {} \; 2>/dev/null

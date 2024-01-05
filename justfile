
search_and_destroy target:
    find . -type d -name '{{target}}' -exec rm -rf {} \; 2>/dev/null

clean:
    set +e
    just search_and_destroy target
    just search_and_destroy _build
    just search_and_destroy result


search_and_destroy target file_type='d':
    @find . -type {{file_type}} -name '{{target}}' -exec rm -rf {} \; 2>/dev/null

clean:
    @set +e
    @just search_and_destroy result l
    @kondo -a -o=20m >/dev/null

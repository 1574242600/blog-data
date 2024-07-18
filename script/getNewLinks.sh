#!/bin/bash

main() {
    local lastJson=$(git show 'HEAD^:data/links.json')
    local nowJson=$(cat data/links.json)

    local lastRss=($(echo "$lastJson" | jq '.[].rss' | tr -d  '"' ))
    local nowRss=($(echo "$nowJson" | jq '.[].rss' | tr -d  '"' ))

    local result="$nowJson"

    for rss in "${nowRss[@]}"; do        
        if [[ "${lastRss[@]}" =~ "$rss" ]]; then
            result=$(echo "$result" | jq "map(select(.rss != \"$rss\"))")
        fi
    done

    echo "$result" | jq "map(select(.rss))"
}

main
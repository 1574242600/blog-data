#!/bin/bash

log_info() {
    echo "[info] $@"
}

log_error() {
    echo "[error] $@"
}

is_number() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

is_json() {
    echo "$1" | jq >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

req_api() {
   curl -s \
   -H "Authorization:GoogleLogin auth=$G_API_TOKEN" \
   "https://freshrss.nworm.icu/api/greader.php/reader/api/0$1"
}

quick_add() {
    local result=$(req_api "/subscription/quickadd/?quickadd=$1")

    if (is_json "$result"); then 
        echo "$result"
    else
        echo "{ \"numResults\": 0, \"error\": \"$result\" }"
    fi
}

move_to_dir() {
    req_api "/subscription/edit?ac=edit&s=$1&a=user%2F-%2Flabel%2F$2"
}

add_friend() {
    local result=$(quick_add "$1")
    local code=$(echo "$result" | jq '.numResults')

    if [[ $code -eq 0 ]]; then
        local error=$(echo "$result" | jq '.error' | tr -d '"')
    
        if [[ $error == "Already subscribed!"* ]]; then
            echo "255 $error"
            return 255
        else
            echo "1 $error"
            return 1
        fi
    fi

    local streamId=$(echo "$result" | jq '.streamId' | tr -d '"' | sed 's/\//%2F/g')
    local result=$(move_to_dir "$streamId" 'Friends')

    if [[ $result != "OK" ]]; then
       echo "2 $result"
       return 2
    fi

    echo 0
}

main() {
    local status=0
    local json=$(cat "$1")
    local count=$(echo "$json" | jq 'length')

    for index in $(seq $count); do
        local item=$(echo "$json" | jq ".[$(( $index - 1 ))]")
        local rss=$(echo "$item" |  jq '.rss' | tr -d '"')

        if [[ $rss == 'null' ]]; then continue; fi

        log_info '正在添加' 
        echo $item | jq

        local result=($(add_friend "$rss"))
        if (is_number ${result[0]}); then
            if [[ ${result[0]} -ne 0 ]]; then 
                status=1;
                log_error "添加失败: ${result[@]}"
            else
                log_info "添加成功"
            fi
        else 
            status=1
            log_error "添加失败: ${result[@]}"
        fi
    done

    return $status
}

main $1
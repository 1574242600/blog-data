#!/bin/bash
log_info() {
    echo "[info] $*"
}


log_error() {
    echo "[error] $*"
}

escape_sed() {
    echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

get_image_blocks() {
   grep -Eo '!\[.*?\]\(http[s]?://.*?\)' "$1"
}

get_suitable_file_ext() {
    grep "$(file -b --mime-type "$1")" /etc/mime.types | awk '{print $2}'
}

gen_unique_filename() {
    local url="$1"
    local prefix="$2"
    local hash=$(echo "$url" | sha256sum - | awk '{print substr($1, 0, 10)}')

    echo "$prefix.$hash"
}

download_image() {
    local url="$1"
    local savepath="$2"

    curl -sfL "$url" -o "$savepath"
    
    if [[ $? -ne 0 ]]; then
        echo 1
        return 1
    fi

    local image_path="$savepath.$(get_suitable_file_ext "$savepath")"
    mv "$savepath" "$image_path"
    echo "0 $image_path"
}

main() {
    local filepath="$1"
    local filename=$(basename "$1")
    local filedir=$(dirname "$filepath")
    local savedir=$(realpath "$filedir/image")
    local image_blocks=($(get_image_blocks "$filepath"))
    local new_image_blocks=()
    
    mkdir -vp "$savedir"
    log_info "$1: 开始处理"

    if [[ ${#image_blocks[@]} -eq 0 ]]; then
        log_info "$1: 未找到远程图片"
        return 0
    fi

    log_info "$1: 已找到 ${#image_blocks[@]} 张远程图片"

    for block in "${image_blocks[@]}"; do
        local url=$(echo "$block" | grep -oP '\(\K[^\)]+')
        local title=$(echo "$block" | grep -oP '\[\K[^\]]+')
        local save_filename=$(gen_unique_filename "$url"  "${filename:0:-3}.$title")
        local savepath="$savedir/$save_filename"
        
        log_info "$1: 开始下载 $block"

        local image_path=''

        if [[ $(ls "$savedir") =~ $save_filename ]]; then
            image_path=$(ls "$savepath"*)
            log_info "$1: 文件已存在 $image_path"
        else
            local result=($(download_image "$url" "$savepath"))
            
            if [[ ${result[0]} -ne 0 ]]; then
                log_info "$1: 下载失败"
                new_image_blocks+=("![$title]($url)")
                continue
            fi 

            image_path="${result[*]}"
            image_path="${image_path:2}"

            log_info "$1: 下载成功 $image_path"
        fi
        
        image_path="./$(realpath --relative-to="$filedir" "$image_path")"
        image_path="${image_path// /\%20}"

        new_image_blocks+=("![$title]($image_path)")
    done

    log_info "$1: 开始替换链接"
    for index in $(seq ${#image_blocks[@]}); do
        index=$(( index - 1 ))
        local old_block="${image_blocks[$index]}"
        local new_block="${new_image_blocks[$index]}"

        sed -i "s#$(escape_sed "$old_block")#$(escape_sed "$new_block")#g" "$filepath" 
        log_info "$1: $old_block -> $new_block"
    done

    log_info "$1: 完成"
}

main "$1"

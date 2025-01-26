#!/bin/bash

gen_prompt() {
    cat <<EOF
你是担任中文翻译、拼写校对和修辞改进的专业人士， 非常熟悉中文和$1。
你负责翻译我博客的中文博文。博文使用 Markdown 排版，包含 FrontMatter，博文一般是关于 WEB, 运维，前端，后端，网络，故障排查等与计算机相关方面的文章，偶尔包括 ACGN 和 现实生活，你对这些方面的知识相当熟悉。
我会给你完整的 md 文件，需要你把内容翻译为$1，并使其更为通俗易懂和精炼。确保意思不变，更具易读性。对于 FrontMatter 则只翻译 title 和 tags 属性。
你需要在翻译后的博文里在开头添加 该博文由 ChatGPT 翻译。
你只能输出完整的 md 文件。
我给了你一万美元小费。
EOF
}

gen_req_json() {
    local json=$(cat <<EOF
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {
      "role": "system",
      "content": ""
    },
    {
      "role": "user",
      "content": ""
    }
  ],
  "temperature": 1,
  "top_p": 1,
  "frequency_penalty": 0,
  "presence_penalty": 0
}
EOF
)
    local lang="$1"
    local mdText="$2"
    local prompt="$(gen_prompt "$lang")"

    json="$(echo "$json" | jq --arg prompt "$prompt" '.messages[0].content = $prompt')"
    json="$(echo "$json" | jq --arg mdText "$mdText" '.messages[1].content = $mdText')"

    echo $json
}

req_api() {
    local json="$1"

    curl -s https://api.chatanywhere.tech/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer sk-LOv3S8nqLjc8bOlGvzSIvP9O4tcDip7ZAIJBdr0seU7TkEW6" \
    -d "$json"
}



main() {
    local lang="$1"
    local mdPath="$2"

    local json=$(gen_req_json "$lang" "")

    echo $(req_api "$json")
}
main $1 $2
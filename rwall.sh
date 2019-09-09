#!/bin/bash

CLIENT_ID='zGYDDPFUGDIoHA'
CLIENT_SECRET='h6pH9W5ke22JO-EzQBJTetVzNaM'
USER_AGENT='test2/0.1 by veegl'

function req {
    local TOKEN=$1
    shift
    curl -A "$USER_AGENT" -H "Authorization: bearer $TOKEN" $@ 2>/dev/null
}

if [ -z $TOKEN ]; then
    echo -n "username: "
    read USERNAME
    echo -n "password: "
    read -s PASSWORD

    TOKEN=$(curl 2>/dev/null \
        -X POST \
        -A "$USER_AGENT" \
        -d "grant_type=password&username=$USERNAME&password=$PASSWORD" \
        --user "$CLIENT_ID:$CLIENT_SECRET" https://www.reddit.com/api/v1/access_token 2>/dev/null |\
        jq '.access_token' -r )

    echo $TOKEN
fi

while true; do
    JSON_RESP=$(req $TOKEN "https://oauth.reddit.com/user/veegl/upvoted?limit=100$AFTER")
    AFTER="&after=$(echo $JSON_RESP | jq -r '.data.after')"
    POSTS=$(echo $JSON_RESP | jq -r '.data.children[] | select(.data.subreddit=="wallpapers").data.name')

    for POST in $POSTS; do
        JSON_RESP=$(req $TOKEN "https://oauth.reddit.com/comments/${POST#t3_}" )
        COMMENT=$(echo $JSON_RESP | jq -r '.[].data.children | map(select(.data.author=="ze-robot")) | .[].data.body')
        echo -e "$COMMENT" |\
            sed -n '/^\* (16:9) /{s/^\* (16:9) //;p}' |\
            cut -d',' -f1 |\
            sed -E 's/^\[[0-9]+.[0-9]+\]//; s/\((.*)\)/\1/'
    done

   [ "${AFTER#*=}" == "null" ] && break
done

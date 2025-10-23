#!/bin/bash
 
# Set BMC info
 
HOST=${HOST}
USER=${USER}
PASSWD=${PASSWD}
export DISPLAY_WIDTH=1280
export DISPLAY_HEIGHT=768
 
if [ -z "$HOST" ];then
        echo please set "HOST" environment !
        exit 1
fi
 
if [ -z "$USER" ];then
        echo please set "USER" environment !
        exit 1
fi
 
if [ -z "$PASSWD" ];then
        echo please set "PASSWD" enviroment !
        exit 1
fi
 
run_sr650(){
        # Login to BMC WEB Server to Get JNLP 
        
        GET_TOKENURL="https://${HOST}/api/login"
        JSON='{
                "username": "'${USER}'",
                "password": "'${PASSWD}'"
        }'

        GET_TOKEN=`curl  -k -X POST -d "${JSON}" ${GET_TOKENURL}  --header "Content-Type: application/json"`

        if [ -z "$GET_TOKEN" ];then
                echo "failed to login to BMC: https://${HOST}"
                exit 1
        fi
        
        TOKEN_SESSION=`echo ${GET_TOKEN}|sed 's/\"//g'|awk -F':' '{print $2}'|sed 's/}//g'`

        if [ -z $TOKEN_SESSION ];then
                echo "cannot get sesion_cookie from response : $TOKEN_SESSION"
                exit 1
        fi
        verty_url="https://${HOST}/api/providers/rp_jnlp"
        DOWN_JAVA_CLIENT="https://${HOST}/download/rp.jnlp"
        verty_result=`curl -s -k -H "Authorization: Bearer ${TOKEN_SESSION}"  ${verty_url}`
        result=`echo ${verty_result}|awk -F',' '{print $1}'|awk -F':' '{print $2}'|sed 's/ //g'`

        if [ "$result" = "0" ];then
        curl -s -k -H "Authorization: Bearer ${TOKEN_SESSION}"  ${DOWN_JAVA_CLIENT} > /app/jviewer.jnlp
        fi
        if [ -f /app/jviewer.jnlp ];then
                chmod +x /app/jviewer.jnlp
        fi
        javaws /app/jviewer.jnlp
}

run_sr660v2(){
        # 登录获取返回
        GET_COOKIE=$(curl -s -k -i -X POST -d "username=${USER}&password=${PASS}" "https://${HOST}/api/session")
        echo $GET_COOKIE

        # 提取 QSESSIONID（从 Set-Cookie 中）
        SESSION=`echo "$GET_COOKIE" | grep -e "QSESSIONID=[^;]\+" | awk -F ' ' '{print $2}'`

        # 提取 JSON 主体部分（{ 开始到 } 结束）
        BODY=$(echo "$GET_COOKIE" | sed -n '/^{/,/}$/p')

        # 提取 CSRFToken
        CSRFTOKEN=$(echo "$BODY" | grep -o '"CSRFToken"[^,}]*' | awk -F'"' '{print $4}')

        echo "Session ID: $SESSION"
        echo "CSRF Token: $CSRFTOKEN"
        COOKIE_DATA="Cookie:lang=zh-cn;$SESSION"
        echo $COOKIE_DATA

        wget -O /app/jviewer.jnlp --no-check-certificate --header="${COOKIE_DATA}" --header="X-CSRFTOKEN:${CSRFTOKEN}" "https://${HOST}/api/remote_control/get/kvm/launch"

       

        if [ -f /app/jviewer.jnlp ];then
                chmod +x /app/jviewer.jnlp
        fi
        javaws /app/jviewer.jnlp
}

getIdracVersion(){
        firm_version=`ipmitool -I lanplus -H ${HOST} -U ${USER} -P ${PASSWD} mc info | grep "Firmware Revision" | awk -F ':' '{printf $NF}' | xargs`
        if [ -z "$firm_version" ];then
                echo "get idrac version faild , no ipmi response [mc info]"
                exit 1
        fi
 
       
        case "$firm_version" in
        "7.20")
            version="sr650"
            run_sr650
            ;;
        "5.85")
            version="sr660_v2"
            run_sr660v2
            ;;
        *)
            version="unknown"
            ;;
    esac

    echo "$version"
}
 
getIdracVersion
 
 


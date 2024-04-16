#!/bin/bash

function buildQueryString() {
    local first=$1
    shift
    if [ -n "$first" ]; then
        printf "%s"  "?$first" "${@/#/\&}"
    else
        printf "%s"
    fi
}

function buildHeaders() {
    local headers=("$@")
    local return_value=""
    for item in "${headers[@]}"; do
        return_value+="--header '${item}' "
    done

    echo $return_value
}


function loadDefaultHeaders() {
    local old_IFS=$IFS
    local IFS='}'
    local json=($(envsubst < $configFileName | jq -c ' try .defaultHeaders[]'))

    if [ -z "$json" ]; then
        return
    fi

    IFS=$old_IFS
    for element in "${json[@]}"; do
        element+="}"
        key=$(echo "$element" | jq -r .key)
        value=$( echo "$element" | jq -r .value)
        defaultHeaders+=("${key}:${value}")
    done
}

function loadRequestParams() {
    local old_IFS=$IFS
    local IFS='}'
    local json=($(envsubst < $requestFileName | jq -c 'try .params[]'))

    if [ -z "$json" ]; then
        return
    fi

    IFS=$old_IFS
    for element in "${json[@]}"; do
        element+="}"
        key=$(echo $element | jq -r .key )
        value=$( echo $element | jq -r .value)
        requestParams+=("${key}=${value}")
    done
}

function loadRequestHeaders() {
    local old_IFS=$IFS
    local IFS='}'
    local json=($(envsubst < $requestFileName | jq -c 'try .headers[]'))

    if [ -z "$json" ]; then
        return
    fi

    IFS=$old_IFS
    for element in "${json[@]}"; do
        element+="}"
        key=$(echo "$element" | jq -r .key)
        value=$( echo "$element" | jq -r .value)
        requestHeaders+=("${key}:${value}")
    done
}


function loadCurlOptions() {
    curlOptions=$(jq -cr '.curlOptions | select(. != null)' $configFileName)
}

function loadRequestName() {
    requestName=$(envsubst < $requestFileName | jq -cr '.name | select(. != null)')
}

function loadRequestDescription() {
    requestDescription=$(jq -cr '.description | select(. != null)' $requestFileName)
}

function loadRequestUri() {
    requestUri=$(envsubst < $requestFileName | jq -cr '.uri | select(. != null)')
}

function loadRequestOutputFormat() {
    requestOutputFormat=$(envsubst < $requestFileName | jq -cr '.outputFormat | select(. != null)')
}

function loadRequestEnvironment() {
    requestEnvironment=$(envsubst < $requestFileName | jq -cr '.environment | select(. != null)')
}

function loadRequestMethod() {
    requestMethod=$(envsubst < $requestFileName | jq -cr '.method | select(. != null)')
}

function loadRequestBody() {
    requestBody=$(envsubst < $requestFileName | jq -c '.body | select(. != null)')
}

function loadCurlCommand() {
    curlCommand="curl "

    if [ ! -z "$curlOptions" ];  then
        curlCommand+="${curlOptions} "
    fi

    if [ ${#defaultHeaders[@]} > 0 ]; then
        curlCommand+=$(buildHeaders "${defaultHeaders[@]}")" "
    fi

    if [ ${#requestHeaders[@]} > 0 ]; then
        curlCommand+=$(buildHeaders "${requestHeaders[@]}")" "
    fi

    curlCommand+="--request ${requestMethod} ${requestUri}"

    if [ ${#requestParams[@]} > 0 ]; then
        curlCommand+=$(buildQueryString "${requestParams[@]}")
    fi
    curlCommand+=" "

    if [ ! -z "$requestBody" ]; then
        curlCommand+="--data-raw ${requestBody} "
    fi

}

function loadOutputFormatCommand() {
    declare -A formatters
    formatters['json']="jq"

    outputFormatCommand=${formatters["$requestOutputFormat"]}
}

function loadRequestEnvironmentFileName() {
    requestEnvironmentFileName=$(pwd)/"${requestEnvironment}.env"
}

function loadArgumentEnvironmentFileName() {
    argumentEnvironmentFileName=$(pwd)/"${argumentEnvironment}.env"
}

function loadEnvironmentVariables() {

    local dotEnvFile=$(pwd)/".env"

    set -a
    [ ! -z $requestEnvironmentFileName ] && [ -f $requestEnvironmentFileName ] && . $requestEnvironmentFileName
    [ ! -z $argumentEnvironmentFileName ] && [ -f $argumentEnvironmentFileName ] && . $argumentEnvironmentFileName
    [ -f $dotEnvFile ] && . $dotEnvFile
    set +a
}

function showHelpMessage() {
    echo "${scriptName} is a handy script to make use of curl easyer. It is a kind of wrapper for it "
    echo
    echo "Script version: ${scriptVersion}"
    echo "Usage: getoverherer.sh [ | goh] [options...]"
    echo "where:"
    echo " -i <file name>.json   Path for the input file with request configuration"
    echo " -e <environment>      Set the environment for the script execution"
    echo "                       This option overrides \"environment\" value in the request file"
    echo "                       The environment is the name of the file (not entire path of it) without .env extension"
    echo "                       The file must exists in same directory where script is executed"
    echo " -f                    Show full response information not only the response itself"
    echo " -v                    Print the script version and quit"
    echo " -h                    Print  help message and quit"

}

function showScriptVersion() {
    echo "${scriptName} version ${scriptVersion}"
}

function loadResponseInfo() {
    responseInfo+="{"

    if [ -z "$requestName" ]; then
        responseInfo+="    \"requestName\": \"${requestName}\", "
    fi
    if [ ! -z $argumentEnvironment ]; then
        responseInfo+="    \"environment\": \"${argumentEnvironment}\", "
    else
        responseInfo+="    \"environment\": \"${requestEnvironment}\", "
    fi
    responseInfo+="    \"command\": \"${curlCommand}\""
    if [ ! -z "$response" ] && [ "$response" != "null" ] && [ "$response" != "" ]; then
        responseInfo+=",    \"response\": ${response}"
    fi
    responseInfo+="}"
}

function showResponseInfo() {
    if [ $showFullResponseInfo = true ]; then
        echo $responseInfo | jq
    else
        echo $responseInfo | jq '.response | select(. != null)'
    fi
}

function sendRequest() {
    response=$(eval $curlCommand)
}

function parseScriptArguments() {

    if [ $# -eq 0 ]; then
        showHelpMessage
        exit 0
    fi

    while getopts ":i:e:fvhE:" option; do
        case $option in
            i)
                requestFileName=${OPTARG}
                ;;
            e)
                argumentEnvironment=${OPTARG}
                loadArgumentEnvironmentFileName
                ;;
            f)
                showFullResponseInfo=true
                ;;
            v)
                showScriptVersion
                exit 0;;
            h)
                showHelpMessage
                exit 0;;
            \?)
                showHelpMessage
                exit 1;;
            :)
                showHelpMessage
                exit 1;;
        esac
    done
}

function validateScriptArguments() {

    if [ -z $requestFileName ]; then
        echo "Error: The -i <file name>.json option is required"
        exit 1
    fi

    if [ ! -f $requestFileName ]; then
        echo "Error: Input file does not exists"
        exit 2
    fi

    if [ ! -z $argumentEnvironmentFileName ] && [ ! -f $argumentEnvironmentFileName ]; then
        echo "Error: Environment file \"${argumentEnvironmentFileName}\" not found"
        exit 2
    fi
}

function validadeValuesFromRequestFile() {
    local validMethods=("GET" "POST" "PUT" "PATCH" "DELETE" )
    local validOutputFormats=("json")


    if [ -z "$requestMethod" ]; then
        echo "Error: Request method not set in the request configuration file."
        exit 3
    fi

    if ! echo "${validMethods[@]}" | grep -q "$requestMethod"; then
        echo "Error: Invalid request method. Valid ones: ${validMethods[@]}"
        exit 3
    fi

    if [ -z "$requestUri" ]; then
        echo "Error: Request uri not found in the request configuration file."
        exit 3
    fi

    if ! echo "${validOutputFormats[@]}" | grep -q "$requestOutputFormat"; then
        echo "Error: Invalid output format. Valid ones: ${validOutputFormats[@]}"
        exit 3
    fi


    if [ ! -z $requestEnvironmentFileName ] && [ ! -f $requestEnvironmentFileName ]; then
        echo "Error: Environment file \"${requestEnvironmentFileName}\" not found"
        exit 3
    fi

}

function main() {

    loadRequestEnvironment
    loadRequestEnvironmentFileName
    loadEnvironmentVariables

    if [ -f $configFileName ]; then
        loadDefaultHeaders
        loadCurlOptions
    fi

    loadRequestHeaders
    loadRequestName
    loadRequestDescription
    loadRequestMethod
    loadRequestUri
    loadRequestParams
    loadRequestBody
    loadRequestOutputFormat

    loadCurlCommand

    if [ ! -z "$requestOutputFormat" ]; then
        loadOutputFormatCommand
    fi

    if [ ! -z "$outputFormatCommand" ]; then
        curlCommand+="| "${outputFormatCommand}
    fi

    validadeValuesFromRequestFile
    sendRequest
    loadResponseInfo
    showResponseInfo
}

function init() {
    scriptName="getoverhere.sh (a.k.a. goh)"
    scriptVersion="1.0.0"
    configFileName=$(pwd)"/GetOverHererFile.json"
    requestFileName=""

    defaultHeaders=()
    curlOptions=""

    requestHeaders=()
    requestName=""
    requestDescription=""
    requestMethod=""
    requestUri=""
    requestParams=()
    requestBody=""
    requestOutputFormat="json"
    requestEnvironment=""
    requestEnvironmentFileName=""

    curlCommand=""
    outputFormatCommand=""
    response=""
    responseInfo=""

    showFullResponseInfo=false
    argumentEnvironment=""
    argumentEnvironmentFileName=""
}

init
parseScriptArguments $@
validateScriptArguments
main


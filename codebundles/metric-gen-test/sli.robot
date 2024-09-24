*** Settings ***
Documentation       This SLI accepts a pattern for generating a sequence of metrics and pushes them to the metric store at the specified interval.
Metadata            Author    j-pye
Metadata            Display Name    Metric Gen

Library             BuiltIn
Library             Collections
Library             String
Library             RW.Core
Library             RW.CLI
Library             RW.platform

Suite Setup         Suite Initialization

*** Tasks ***
Pull and Push Next Metric
    [Documentation]    Use cURL to pull the next generated metric value and push it to the metric store.
    ...    Fail the task when the next value is '_' and don't push a metric.
    ${payload}=    Create Dictionary    unique_name=${unique_name}    pattern=${GENERATION_PATTERN}
    ${payload_json}=    Evaluate    json.dumps(${payload})    modules=json
    ${curl_command}=    Set Variable    curl -s -w '\%{http_code}' -X POST -H "Content-Type: application/json" -d '${payload_json}' ${URL}/sequence.v1.SequenceService/NextInSequence
    ${curl_rsp}=    RW.CLI.Run Cli    cmd=${curl_command}
    ${status_code}=    Get Substring    ${curl_rsp.stdout}    -3
    ${response_body}=    Remove String    ${curl_rsp.stdout}    ${status_code}
    Should Be Equal As Integers    ${status_code}    200    msg=${response_body}
    ${response}=    Evaluate    json.loads('${response_body}')    modules=json
    ${metric}=    Get From Dictionary    ${response}    metric
    IF    '${metric}' == '_'
        Fail    msg=Intentionally Failing to Indicate Skipped Metric Push
    ELSE
        RW.Core.Push Metric    ${metric}
    END

*** Keywords ***
Suite Initialization
    ${URL}=    RW.Core.Import User Variable    URL
    ...    type=string
    ...    description=What URL to request the next metric from.
    ...    pattern=\w*
    ...    default=https://metric-gen-582160791695.us-central1.run.app
    ...    example=https://metric-gen-host
    ${GENERATION_PATTERN}=    RW.Core.Import User Variable
    ...    GENERATION_PATTERN
    ...    type=string
    ...    description=Generation Pattern is a Short Notation that's expanded to produce a sequence of metrics. See README.md for details.
    ...    pattern=\w*
    ...    default=1

    ${RW_SLX}=    RW.Core.Import Platform Variable    RW_SLX
    ${RW_LOCATION_UUID}=    RW.Core.Import Platform Variable    RW_LOCATION_UUID
    ${unique_name}=    Set Variable    ${RW_SLX}_${RW_LOCATION_UUID}
    Set Suite Variable    ${unique_name}
*** Settings ***
Documentation       This Runbook gets the full sequence of metrics for the GENERATION GENERATION_PATTERN used in the SLI.
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
Get Full Sequence
    [Documentation]    Use cURL to pull the next generated metric value and push it to the metric store.
    ...    Fail the task when the next value is '_' and don't push a metric.
    ${payload}=    Create Dictionary    unique_name=${unique_name}
    ${payload_json}=    Evaluate    json.dumps(${payload})    modules=json
    ${curl_command}=    Set Variable    curl -s -w '\%{http_code}' -X POST -H "Content-Type: application/json" -d '${payload_json}' ${URL}/sequence.v1.SequenceService/GetFullSequence
    ${curl_rsp}=    RW.CLI.Run Cli    cmd=${curl_command}
    ${status_code}=    Get Substring    ${curl_rsp.stdout}    -3
    ${response_body}=    Remove String    ${curl_rsp.stdout}    ${status_code}
    Should Be Equal As Integers    ${status_code}    200    msg=${response_body}
    ${response}=    Evaluate    json.loads('${response_body}')    modules=json
    ${sequence}=    Get From Dictionary    ${response}    sequence
    RW.Core.Add Pre To Report   SLI Generation Pattern: ${GENERATION_PATTERN}
    RW.Core.Add Pre To Report   SLI Generation Sequence: ${sequence}

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

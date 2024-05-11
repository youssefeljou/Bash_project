#!/bin/bash

errorCount=0
warningCount=0
declare -a errors=()
declare -a warnings=()
declare -a eventsTracked=()
declare -a eventsChecked=("System Startup Sequence Initiated" "System health check OK")

error_count() {
    if [[ "$logLevel" == "ERROR" ]]; then
        ((errorCount++))
        errors+=("ERROR: $message")
    fi
}

warning_count() {
    if [[ "$logLevel" == "WARN" ]]; then
        ((warningCount++))
        warnings+=("WARNING: $message")
    fi
}

event_track() {
    if [[ $message == *"System Startup Sequence Initiated"* ]]; then
        eventsTracked+=("System Startup Sequence Initiated")
    elif [[ $message == *"System health check OK"* ]]; then
        eventsTracked+=("System health check OK")
    fi
}

generate_report() {
    echo "*******Report Summary*******"
    echo "Error Count: $errorCount"
    echo "Warning Count: $warningCount"
    echo "Events Tracked:"
    for event in "${eventsTracked[@]}"; do
        echo "- $event"
    done
    echo
    if [[ ${#eventsTracked[@]} -gt 0 ]]; then
        echo "System Event Status:"
        for event in "${eventsChecked[@]}"; do
            if grep -q "$event" file.log; then
                echo "- $event: Success"
            else
                echo "- $event: Not Found"
            fi
        done
    else
        echo "No system events tracked."
    fi
    echo
}

read_log_file() {
    if [ -f "file.log" ]; then
        while IFS= read -r log_entry; do
            #[2024-04-06 08:15:32] INFO System Startup Sequence Initiated
            #    1          2        3 
            logLevel=$(echo "$log_entry" | awk '{print $3}') #INFO WARN ERROR
            message=$(echo "$log_entry" | awk '{$1=$2=$3=""; print $0}') #ALL EXCEPT 1 2 3
            error_count
            warning_count
            event_track
        done < "file.log"
    else
        echo "Error: Log file 'file.log' not found."
        exit 1
    fi
}

main() {
    read_log_file
    while true; do
        read -p "Enter
    1: Summarize errors
    2: Summarize warnings
    3: Generate report
    4: Exit
    " choice
        case "$choice" in
        1)
            echo "Error count is ${errorCount}"
            for error in "${errors[@]}"; do
                echo "$error"
            done
            echo
            ;;
        2)
            echo "Warning count is ${warningCount}"
            for warning in "${warnings[@]}"; do
                echo "$warning"
            done
            echo
            ;;
        3)
            generate_report
            ;;
        4)
            echo "Exiting program."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, 3, or 4."
            ;;
        esac
    done
}

main

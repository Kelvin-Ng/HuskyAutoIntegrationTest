#!/bin/bash

if [[ $# != 8 ]]
then
    echo "Usage: ./run.sh <path to machine list> <path to cmd_timeout_extra_config_list file> <path to base conf> <base dir of running> <path to master exec> <log output dir> <tmp file dir> <path email list>"
    exit 0
fi

# machines to run on
MACHINE_CFG_FILE=$1

# cmd should not include the switch for the config because the config will be generated
# timeout = 0 means no timeout
# extra_config is the config specific to the test
CMD_TIMEOUT_EXTRA_CONFIG_LIST_FILE=$2

# config file common to all tests
BASE_CONF_FILE=$3

# cd to this directory to run the commands
RUN_BASE_DIR=$4

# path to the master executable
MASTER_EXEC_PATH=$5

# path to output logs to
LOG_OUTPUT_DIR_BASE=$6

# path to output tmp files
# must be accessible from all machines
TMP_FILE_DIR=$7

# list of emails to notify when errors occur
EMAIL_LIST_FILE=$8 

EMAIL_LIST=`cat $EMAIL_LIST_FILE`

function send_email {
    mail -s 'Husky Integration Test Failed' $EMAIL_LIST << EOF
The following error occurred when running the integration test for Husky:
$@
EOF
}

CMD_I=1

while read line
do
    IFS=' '
    line_array=($line)
    unset IFS

    CMD=${line_array[0]}
    TIMEOUT=${line_array[1]} # 0 means no timeout
    EXTRA_CONFIG=${line_array[2]}

    FULL_CONFIG_FILE="$TMP_FILE_DIR/$CMD_I.conf"
    if [ -z "$EXTRA_CONFIG" ]
    then
        cp "$BASE_CONF_FILE" "$FULL_CONFIG_FILE"
    else
        cat "$EXTRA_CONFIG" "$BASE_CONF_FILE" > "$FULL_CONFIG_FILE"
    fi

    FULL_CMD="$CMD -C $FULL_CONFIG_FILE"


    $MASTER_EXEC_PATH -C "$FULL_CONFIG_FILE" > "$LOG_OUTPUT_DIR_BASE/$CMD_I/master.log" 2>&1 &
    master_pid=$!
    start_timestamp=`date +%s%N`
    pssh_output=$(pssh -o "$LOG_OUTPUT_DIR_BASE/$CMD_I" -t $TIMEOUT -P -h $MACHINE_CFG_FILE -x "-t -t" "ulimit -c unlimited && cd \"$RUN_BASE_DIR\" && $FULL_CMD")
    end_timestamp=`date +%s%N`
    time_spent=$(($end_timestamp - $start_timestamp))
    kill $master_pid

    pssh_output_failure=`echo "$pssh_output" | grep FAILURE`

    if [[ ${#pssh_output_failure} == 0 ]]
    then
        echo "$CMD_I |$FULL_CMD| $time_spent succeed"
    else
        pssh_output_timeout=`echo "$pssh_output_failure" | grep "Timed out"`
        if [[ ${#pssh_output_timeout} != 0 ]]
        then
            echo "$CMD_I |$FULL_CMD| timed out"
            send_email "$CMD_I |$FULL_CMD| timed out"
        else
            pssh_output_exit_code=`echo "$pssh_output_failure" | grep "Exited with error code" | awk 'NF>1{print $NF}'`
            
            output="$CMD_I |$FULL_CMD|"
            for code in $pssh_output_exit_code
            do
                output+=" $code"
            done
            echo $output
            send_email $output
        fi
    fi

    ((CMD_I++))

done < "$CMD_TIMEOUT_EXTRA_CONFIG_LIST_FILE"


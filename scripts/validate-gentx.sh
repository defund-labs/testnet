#!/bin/bash

set -x 

DEFUNDD_HOME="/tmp/defundd$(date +%s)"
RANDOM_KEY="randomdefunddvalidatorkey"
CHAIN_ID=defund-private-2
DENOM=ufetf
VALIDATOR_COINS=100000000$DENOM
MAXBOND=90000000
GENTX_FILE=$(find ./$CHAIN_ID/gentx -iname "*.json")
LEN_GENTX=$(echo ${#GENTX_FILE})
DEFUNDD_TAG="v0.1.0-alpha"
BUILD_DIR="./build"

# Gentx Start date
start="2022-10-28 00:00:00Z"
# Compute the seconds since epoch for start date
stTime=$(date --date="$start" +%s)

# Gentx End date
end="2022-10-29 00:00:00Z"
# Compute the seconds since epoch for end date
endTime=$(date --date="$end" +%s)

# Current date
current=$(date +%Y-%m-%d\ %H:%M:%S)
# Compute the seconds since epoch for current date
curTime=$(date --date="$current" +%s)

if [[ $curTime < $stTime ]]; then
    echo "start=$stTime:curent=$curTime:endTime=$endTime"
    echo "Gentx submission is not open yet. Please close the PR and raise a new PR after 24-October-2022 01:00:00 UTC"
    exit 1
else
    if [[ $curTime > $endTime ]]; then
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
        echo "Gentx submission is closed"
        exit 1
    else
        echo "Gentx is now open"
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
    fi
fi

if [ $LEN_GENTX -eq 0 ]; then
    echo "No new gentx file found."
    exit 1
else
    set -e

    echo "GentxFiles::::"
    echo $GENTX_FILE

    echo "...........Init Defund.............."

    git clone https://github.com/defund-labs/defund
    cd defund
    git checkout $DEFUNDD_TAG
    make build
    chmod +x $BUILD_DIR/defundd

    $BUILD_DIR/defundd keys add $RANDOM_KEY --keyring-backend test --home $DEFUNDD_HOME

    $BUILD_DIR/defundd init --chain-id $CHAIN_ID validator --home $DEFUNDD_HOME

    echo "..........Fetching genesis......."
    rm -rf $DEFUNDD_HOME/config/genesis.json
    cp ../$CHAIN_ID/pre-genesis.json $DEFUNDD_HOME/config/genesis.json

    # this genesis time is different from original genesis time, just for validating gentx.
    sed -i '/genesis_time/c\   \"genesis_time\" : \"2021-09-02T16:00:00Z\",' $DEFUNDD_HOME/config/genesis.json

    find ../$CHAIN_ID/gentx -iname "*.json" -print0 |
        while IFS= read -r -d '' line; do
            GENACC=$(cat $line | sed -n 's|.*"delegator_address":"\([^"]*\)".*|\1|p')
            denomquery=$(jq -r '.body.messages[0].value.denom' $line)
            amountquery=$(jq -r '.body.messages[0].value.amount' $line)

            echo $GENACC
            echo $amountquery
            echo $denomquery

            # only allow $DENOM tokens to be bonded
            if [ $denomquery != $DENOM ]; then
                echo "invalid denomination"
                exit 1
            fi

            # limit the amount that can be bonded
            if [ $amountquery -gt $MAXBOND ]; then
                echo "bonded too much: $amountquery > $MAXBOND"
                exit 1
            fi

            $BUILD_DIR/defundd add-genesis-account $(jq -r '.body.messages[0].delegator_address' $line) $VALIDATOR_COINS --home $DEFUNDD_HOME
        done

    mkdir -p $DEFUNDD_HOME/config/gentx/

    # add submitted gentxs
    cp -r ../$CHAIN_ID/gentx/* $DEFUNDD_HOME/config/gentx/

    echo "..........Collecting gentxs......."
    $BUILD_DIR/defundd collect-gentxs --home $DEFUNDD_HOME &> log.txt
    sed -i '/persistent_peers =/c\persistent_peers = ""' $DEFUNDD_HOME/config/config.toml
    sed -i '/minimum-gas-prices =/c\minimum-gas-prices = "0.25ufetf"' $DEFUNDD_HOME/config/app.toml

    $BUILD_DIR/defundd validate-genesis --home $DEFUNDD_HOME

    echo "..........Starting node......."
    $BUILD_DIR/defundd start --home $DEFUNDD_HOME &

    sleep 90s

    echo "...checking network status.."

    $BUILD_DIR/defundd status --node http://localhost:26657

    echo "...Cleaning the stuff..."
    killall defundd >/dev/null 2>&1
    rm -rf $DEFUNDD_HOME >/dev/null 2>&1
fi

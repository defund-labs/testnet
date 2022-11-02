#!/bin/bash

for FILE in $HOME/.defund/config/gentx/*; do 
    ADDR=$(cat $FILE | jq -r '.body.messages[0].delegator_address')
    defundd add-genesis-account "$ADDR" "90000000ufetf"
done
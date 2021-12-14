#!/bin/bash

localKey="BKeXkDQ25EYdqJ3MTyS7M4ujoDnpVEwu1h"

logfile='/home/olafur/Documents/textlog.txt'
# Make sure the logfile exists, otherwise create it
if [ ! -f $logfile ];
then
touch $logfile;
fi

# Check if there is an incoming argument
if [ $# -lt 1 ]; then echo "Missing arguments" >> $logfile; fi

TxID=$1

# Ckeck if transaction has been processe before
exists=$(grep -o "$TxID" $logfile | wc -l)
if [ "$exists" -gt 0 ]; then exit; fi

# Get the raw transaction
getRawTransaction=$(smileycoin-cli getrawtransaction "$TxID")

# Decode the transaction
decodedRawTransaction=$(smileycoin-cli decoderawtransaction "$getRawTransaction")

# Get the address of the player
addresses=`smileycoin-cli decoderawtransaction $getRawTransaction | grep '"B' | sed -e 's/ *//g' -e 's/"//g'`
playerAddress=$(echo $addresses | head -n1 | awk '{print $2;}')

input=$(echo "$decodedRawTransaction" | grep -B 8 "$localKey")

if [ -z "$input" ];
then
exit;
fi

value=$(echo "$input" | awk '/"value"/ {print $3}' | sed 's/,$//')
vout=$(echo "$input" | awk '/"n"/ {print $3}' | sed 's/,$//')
winnings=$( expr $value*2 | bc)

# Reyna að finna OP_RETURN strenginn til að athuga hvort það sé vinningur
getMsg1=$(smileycoin-cli getrawtransaction $TxID)
getMsg2=$(smileycoin-cli decoderawtransaction $getMsg1 | awk '/"txid"/ {print $3}' | tail -1 | sed 's/"//g' | sed 's/,$//')
getMsg3=$(smileycoin-cli getrawtransaction $getMsg2)
message=$(smileycoin-cli decoderawtransaction $getMsg3 | grep "6a0" | awk '/"hex"/ {print $3}' | sed 's/"//g' | sed 's/,$//')

echo "Message: $message"

# Ef þessi strengur "6a0199" kom með OP_RETURN þá er þetta vinningur og bottinn sendir til baka vinninginn
if [ "$message" = "6a0199" ]
then
  smileycoin-cli sendtoaddress $playerAddress $winnings
  echo "playerAddress: $playerAddress" >> $logfile
  echo "Value: $value" >> $logfile
  echo "Winnings: $winnings" >> $logfile
  exit
elif [ -z "$message" ]
then
  echo "No message" >> $logfile
  exit
else
  echo "YOU LOSE" >> $logfile
fi

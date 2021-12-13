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

#winnings=$( expr 2*$value | bc)    LAGA ÞEGAR GUNNAR SVARAR

winnings=$( expr $value | bc)

getMsg1=$(smileycoin-cli getrawtransaction $TxID)
getMsg2=$(smileycoin-cli decoderawtransaction $getMsg1 | awk '/"txid"/ {print $3}' | tail -1 | sed 's/"//g' | sed 's/,$//')
getMsg3=$(smileycoin-cli getrawtransaction $getMsg2)
message=$(smileycoin-cli decoderawtransaction $getMsg3 | grep "6a0" | awk '/"hex"/ {print $3}' | sed 's/"//g' | sed 's/,$//')

echo "Message: $message"

echo "Message: $message" >> $logfile

if [ "$message" = "6a0199" ]
then
  # Create a new raw transaction to return winnings to player
  rawTransaction=$(smileycoin-cli createrawtransaction '[{"txid" : "'$TxID'","vout" : '$vout'}]' '{"'$playerAddress'" : '$winnings'}')

  # Sign the transaction
  signedTransaction=$(smileycoin-cli signrawtransaction "$rawTransaction")

  # Get the signed transaction
  signedHex=$(echo "$signedTransaction" | awk '/"hex"/ {print $3}' | sed 's/"//g' | sed 's/,$//')

  # Send the transaction
  # smileycoin-cli sendrawtransaction $signedHex             ÞETTA ÞARF AÐ LAGA ÞEGAR GUNNAR SVARAR, FINNA EITTHVAÐ UTXO SEM HÆGT ER AÐ NOTA

  echo "Value: $value" >> $logfile
  echo "Winnings: $winnings" >> $logfile
elif [ -z "$message" ]
then
  echo "No message" >> $logfile
else
  echo "YOU LOSE" >> $logfile
  # BÆTA VIÐ VIRKNI TIL AÐ SENDA HLUTA TIL GÓÐGERÐARMÁLA EÐA GERA ÞAÐ Í LEIKJASKRIFTUNNI
fi

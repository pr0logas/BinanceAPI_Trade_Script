#!/usr/bin/env bash

##: Author: Tomas Andriekus
##: 2018-08
##: v1.1

boughtAT=$(echo $price)

while :
do

# Curl The Price
current_price=$(curl -s https://www.binance.com/api/v1/ticker/24hr?symbol=BTCUSDT | jq '.lastPrice' | sed -e 's/"//g' | cut -f1 -d".")

# Calc the diff in USD
diff_in_USD=$(echo $current_price'-'$boughtAT | bc)
diff_in_percent=$(echo "scale=2; $diff_in_USD*100/$boughtAT" | bc -l)

APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
symbol=BTCUSDT
recvWindow=3000
price=$(echo $boughtAT.00'+'35 | bc)
quantity=0.200000
side=SELL
echo "$(date +%s%N | cut -b1-13)" > /tmp/btc_echo_date.txt
timestamp=$(cat /tmp/btc_echo_date.txt)

echo -e "\e[1;32mYou should sell! Diff was $diff_in_USD USD\e[0m"
echo "$(date) You should sell! Diff was $diff_in_USD USD" >> /tmp/btc_should_i_sell.txt
echo ""
signature=$(echo -n "symbol=$symbol&side=$side&type=LIMIT&timeInForce=GTC&quantity=$quantity&price=$price&recvWindow=$recvWindow&timestamp=$timestamp" | openssl dgst -sha256 -hmac "$SECRETKEY" | cut -c10-80)

status=$(/usr/bin/curl -s -H "X-MBX-APIKEY: $APIKEY" -X POST 'https://api.binance.com/api/v3/order' -d "symbol=$symbol&side=$side&type=LIMIT&timeInForce=GTC&quantity=$quantity&price=$price&recvWindow=$recvWindow&timestamp=$timestamp&signature=$signature")

if [ "$(echo "$status" | grep -c "insufficient balance")" -eq 1 ];
then
        echo "Insufficient balance or order already placed!"
elif
        [ "$(echo "$status" | grep -c "NEW")" -eq 1 ];
then
        echo "Order successfully placed for $side to the eXchange at price: $price & quantity: $quantity BTC" && exit 1
        #source ~/btc_buy.sh
fi

	sleep 8
done

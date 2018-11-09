#!/usr/bin/env bash

##: Author: Tomas Andriekus
##: 2018-08
##: v1.1

rm -fr /tmp/btc_price_file_*
rm -fr /tmp/btc_count_file.txt

while :
do

# The place of count file
count_file=/tmp/btc_count_file.txt

# Check if file exist
if [ ! -f $count_file ]; then
    touch $count_file
fi

# Check if file not empty
if [ -s $count_file ];
then
	echo ""
else
	echo "1" > $count_file
fi

# Find the number in file
count_number=$(cat $count_file)
price_file=/tmp/btc_price_file_$count_number.txt

current_price=$(curl -s https://www.binance.com/api/v1/ticker/24hr?symbol=BTCUSDT | jq '.lastPrice' | sed -e 's/"//g' | cut -f1 -d".")

price_file_to_watch=$(cat /tmp/btc_price_file_$count_number.txt)
diff_in_USD=$(echo "$current_price - $price_file_to_watch - 1" | bc)
diff_in_percent=$(echo "scale=2; $diff_in_USD*100/$price_file_to_watch" | bc -l)

if [ "$diff_in_USD" -lt "0" ];
then
echo "$(date +%Y-%m-%d:%H:%M:%S) You want to BUY BTC at lowest price:" | tee -a /tmp/btc_buying_log.txt
echo -e "Current Price: \e[1;33m$current_price\e[0m USD // Before 70 sec Price was: \e[1;32m$price_file_to_watch\e[0m USD // Diff: \e[1;32m$diff_in_USD\e[0m USD // Diff in %: \e[1;32m$diff_in_percent\e[0m %" | tee -a /tmp/btc_buying_log.txt
else
echo "$(date +%Y-%m-%d:%H:%M:%S) You want to BUY BTC at lowest price:" | tee -a /tmp/btc_buying_log.txt
echo -e "Current Price: \e[1;33m$current_price\e[0m USD // Last Price: \e[1;31m$price_file_to_watch\e[0m USD // Diff: \e[1;31m$diff_in_USD\e[0m USD // Diff in %: \e[1;31m$diff_in_percent\e[0m %" | tee -a /tmp/btc_buying_log.txt
fi

APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
symbol=BTCUSDT
recvWindow=3000
price=$(echo $current_price.00'-'4 | bc)
quantity=0.200000
side=BUY
echo "$(date +%s%N | cut -b1-13)" > /tmp/btc_echo_date.txt
timestamp=$(cat /tmp/btc_echo_date.txt)

if [ "$diff_in_USD" -lt "-30"  ];
then 
	echo -e "\e[1;32mYou should buy! Diff was $diff_in_USD USD\e[0m"
	echo "$(date) You should buy! Diff was $diff_in_USD USD" >> /tmp/btc_should_i_buy.txt

	# Create signature;
	signature=$(echo -n "symbol=$symbol&side=$side&type=LIMIT&timeInForce=GTC&quantity=$quantity&price=$price&recvWindow=$recvWindow&timestamp=$timestamp" | openssl dgst -sha256 -hmac "$SECRETKEY" | cut -c10-80)

	# Push order to eXchange and get the status;
	status=$(/usr/bin/curl -s -H "X-MBX-APIKEY: $APIKEY" -X POST 'https://api.binance.com/api/v3/order' -d "symbol=$symbol&side=$side&type=LIMIT&timeInForce=GTC&quantity=$quantity&price=$price&recvWindow=$recvWindow&timestamp=$timestamp&signature=$signature") 
fi

if [ "$(echo "$status" | grep -c "insufficient balance")" -eq 1 ];
then
        echo "Insufficient balance or order already placed!" && exit 1
elif
        [ "$(echo "$status" | grep -c "NEW")" -eq 1 ];
then
	echo ""
        echo "Order successfully placed for $side to the eXchange at price: $price & quantity: $quantity BTC"
	echo ""
        #source ~/btc_sell.sh
fi

# Store price to file
echo "$current_price" > $price_file

# Check if file contains number 10;
if [ "$count_number" -eq 40 ];
then
        echo "1" > $count_file
else
	new_number=$(echo "$count_number + 1" | bc)
	echo "$new_number" > $count_file
fi
	sleep 8
done

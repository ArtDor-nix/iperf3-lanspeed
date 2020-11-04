#!/bin/bash

table=$"ping1"
ID=$"0"
user=$"root"
pass=$"123456@a"
database="OUO"
fping1=$"/usr/local/sbin/fping"
while true;
do
mysql -u $user -p$pass -D $database -e "ALTER TABLE $table AUTO_INCREMENT = 0;"
mysql -u $user -p$pass -D $database -e "INSERT IGNORE INTO $table (HostName) SELECT Name FROM iperf;"
#mysql -u $user -p$pass -D $database -e "DELETE FROM $table AS t1 WHERE t1.HostName NOT IN (SELECT t2.HostName FROM iperf AS t2);"
mysql -u $user -p$pass -D $database -e "set @i := -1; update $table set id = (@i := @i+1) order by id;"
data=$(mysql -u $user -p$pass -D $database -e "SELECT HostName FROM $table WHERE id = $ID;" -B --skip-column-names)
time=$(mysql -u $user -p$pass -D $database -e "SELECT iperf_date FROM $table WHERE id = $ID;" -B --skip-column-names)
quantity=$(mysql -u $user -p$pass -D $database -e "SELECT id FROM $table ORDER BY id DESC LIMIT 1;" -B --skip-column-names)
speedtab=$(mysql -u $user -p$pass -D $database -e "SELECT lan_speed FROM $table WHERE id = $ID;" -B --skip-column-names)
echo $speedtab
#echo $quantity
limit=$(($quantity+1))
echo $limit
echo $time
echo $data
result=$($fping1 $data | awk '{print $3}')
unixtime=$(date --date="$time" '+%s')
realtime=$(($unixtime+604800))
echo $unixtime
echo $realtime
now=$(date +%s)
echo $result
case $result in
"alive") mysql -u $user -p$pass -D $database -e "UPDATE $table SET result = 1 WHERE id = $ID;"
if [ "$now" -ge "$realtime" ];
then
speed=$(iperf3 -c $data -t 3 --connect-timeout 3000 | sed 1,9d | awk '{print $7}'| cut -d "." -f 1)
different=$(($speed-$speedtab))
mysql -u $user -p$pass -D $database -e "UPDATE $table SET lan_speed = '$speed' WHERE id = $ID;"
mysql -u $user -p$pass -D $database -e "UPDATE $table SET ping_date = NOW() WHERE id = $ID;"
mysql -u $user -p$pass -D $database -e "UPDATE $table SET difference = '$different' WHERE id = $ID;"
elif [ "$now" -lt "$realtime" ];
then echo "to early"
fi
if [ "$speed" -lt 1000 ]; then
mysql -u $user -p$pass -D $database -e "UPDATE $table SET iperf_date = NOW() WHERE id = $ID;"
else
echo "`date` $data connection error">>error.log
fi
sleep 10;;
"unreachable") mysql -u $user -p$pass -D $database -e "UPDATE $table SET result = 0 WHERE id = $ID;"
#mysql -u $user -p$pass -D $database -e "UPDATE $table SET lan_speed = '_' WHERE id= $ID;"
esac
ID=$(( $ID + 1 ))
echo $ID
if [ $ID -eq $limit ]
then
break
fi
done


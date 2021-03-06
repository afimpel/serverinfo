#!/bin/sh
paths="/www/dokuwiki/data/pages"
filename="start.txt"
cpuinfoCore=$(grep cores /proc/cpuinfo | uniq -c | tr -t ' ' ' ')
IFS=" " read -a cores_array00 <<< $cpuinfoCore
coresThreads="${cores_array00[3]} Cores     ^     ${cores_array00[0]} Threads"

echo "~~NOCACHE~~" > ${paths}/${filename} 
echo "====== Server Info ======" >> ${paths}/${filename}
echo "===== Resume =====" >> ${paths}/${filename}
echo "| SO       ^         [[$(grep HOME_URL /etc/os-release  | cut -d '"' -f 2)|$(grep PRETTY_NAME /etc/os-release  | cut -d '"' -f 2)]] ^^^" >> ${paths}/${filename}
echo "| Kernel   ^         $(uname -r) at $(uname -m) ^^^" >> ${paths}/${filename}
echo "| UserName ^         $(whoami)@$(hostname) ^^^"  >> ${paths}/${filename}
echo "| Datetime ^         $(date) ^^^" >> ${paths}/${filename}
echo "| Uptime   ^         $(uptime) ^^^" >> ${paths}/${filename}
echo "| HardWare ^         $(cat /sys/devices/virtual/dmi/id/chassis_vendor) $(cat /sys/devices/virtual/dmi/id/product_version) ^^^" >> ${paths}/${filename}
echo "| CPU      ^         $(grep model /proc/cpuinfo | cut -d : -f 2 | tail -1 | sed 's/\s//') ^     ${coresThreads}     ^" >> ${paths}/${filename}
echo " " >> ${paths}/${filename}
cpunum=0
echo "===== CPU Temp =====" >> ${paths}/${filename}
for coretemp_str in $(cat /sys/class/thermal/thermal_zone*/temp | sed 's/\(.\)..$/.\1°C/')
do
    echo "| CPU${cpunum} ^        ${coretemp_str} ^ " >> ${paths}/${filename}
    cpunum=$(( cpunum + 1 ));
done

myip=$(curl ipecho.net/plain -s)

echo "===== Memory =====" >> ${paths}/${filename}
num=0
string="^ "
barrita="^"

for i in $(free -h)
do
    string="$string$barrita $i "
    if [ $num = 5 ]; then
        echo "$string$barrita" >> ${paths}/${filename}
        string=""
        barrita="|"
    fi

    if [ $num = 12 ]; then
        echo "$string|" >> ${paths}/${filename}
        string=""
    fi

    if [ $num = 16 ]; then
        echo "$string| |||" >> ${paths}/${filename}
        string=""
    fi
    num=$(( num + 1 ));
done
echo " " >> ${paths}/${filename}

echo "===== Disk =====" >> ${paths}/${filename}
numdisk=1
stringdisk=""
tops=0
barrita="^"
for i in $(df -h -t ext4)
do
    if [ $numdisk = 7 ] && [ $tops = 0 ]; then
        stringdisk="$stringdisk$i "
        tops=1
        barritafin=$barrita
        barrita="|"
    else
        stringdisk="$stringdisk$barrita $i "
        barritafin=$barrita
    fi
    if [ $numdisk != 1 ]; then
        resto=$((($numdisk-1)%6))
        if [ $resto = 0 ]; then
            echo "$stringdisk $barritafin" >> ${paths}/${filename}
            stringdisk=""
        fi
    fi
    numdisk=$(( numdisk + 1 ));
done
echo " " >> ${paths}/${filename}

echo "=====  IP Address =====" >> ${paths}/${filename}
echo "^ Scope ^ Interface ^ IP ^" >> ${paths}/${filename}
echo "| Public || ${myip} |" >> ${paths}/${filename}
#print "public : \t\t" $myip
for address_str in $(/sbin/ip addr show | grep 'inet ' | grep -v '127.0.0.1'| awk '{ 
if ($5 =="scope")
        print ":" $3 ":" $7 ":" $2 ":"
else
        print ":" $4 ":" $5 ":" $2 ":" 
}')
do
    oldstr=":"
    newstr=' | '
    echo $(echo $address_str | sed "s/$oldstr/$newstr/g") >> ${paths}/${filename}
done
echo "" >> ${paths}/${filename}
echo "===== DMI =====" >> ${paths}/${filename}
cd /sys/devices/virtual/dmi/id/
for dmi_str in $(ls -Sp)
do
    line=$(cat $dmi_str)
    if [ ! -z "${line}" ] && [ 85 -gt ${#line} ]; then
        echo "| ${dmi_str} ^        ${line} ^ " >> ${paths}/${filename}
    fi
done

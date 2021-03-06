#!/bin/bash

# 3PAR Nagios check script v0.3
# Last update 2010/05/14 fredl@3par.com
# Last update 2011/03/03 ddu@antemeta.fr
# Last update 2016/12/16 yves.vaccarezza@corsedusud.fr
#
# This script is provided "as is" without warranty of any kind and 3PAR specifically disclaims all implied warranties of merchantability,
# non-infringement and fitness for a particular purpose. In no event shall 3PAR have any liability arising out of or related to
# customer's 'use of the script including lost data, lost profits, or any direct or indirect, incidental, special, or
# consequential damages arising there from.
# In addition, 3PAR reserves the right not to perform fixes or updates to this script
#
#
# Usage : check_3par InServ Username Command
#
# Supported commands
# check_pd : Check status of physical disks
# Degraded -> Warning
# Failed -> Critical
#
# check_node : Check status of controller nodes
# Degraded -> Warning
# Failed -> Critical
#
# check_ld : Check status of logical disks
# Degraded -> Warning
# Failed -> Critical
#
# check_vv : Check status of virtual volumes
# Degraded -> Warning
# Failed -> Critical
#
# check_port_fc : Check status of virtual volumes
# loss_sync -> Warning
# config_wait -> Warning
# login_wait -> Warning
# non_participate -> Warning
# error -> Critical
#
# check_cap_fc : Check used FC capacity
# >= $PCWARNINGFC -> Warning
# >= $PCCRITICALFC -> Critical
#
# check_cap_nl : Check used NL capacity
# >= $PCWARNINGNL -> Warning
# >= $PCCRITICALNL -> Critical
#
# check_cap_ssd : Check used SSD capacity
# >= $PCWARNINGSSD -> Warning
# >= $PCCRITICALSSD -> Critical
#
# check_ps : Check Power Supply Node
# Degraded -> Warning
# Failed -> Critical
#
# check_ps_cage : Check Power Supply Cage
# Degraded -> Warning
# Failed -> Critical
#
## check_volume : Check cpacity volume
# >= WARNING -> Warning
# >= CRITICAL -> Critical
#
#

if [ "$1" == "" ] || [ $2 == "" ] || [ $3 == "" ]
then
echo Invalid usage : check_3par InServ Username/passwordfile Command
exit 3
fi

INSERV=$1
USERNAME=$2
COMMAND=$3
#VMFS=$4
#IPNUTFILE=$4
TMPDIR=/var/lib/zabbixs/3par
PCCRITICALFC=90
PCWARNINGFC=80
PCCRITICALNL=95
PCWARNINGNL=90
PCWARNINGSSD=90
PCCRITICALSSD=95
CRITICAL=90
WARNING=80


# To connect using the 3PAR CLI, uncomment the following line
#CONNECTCOMMAND="/opt/3PAR/inform_cli_2.3.1/bin/cli -sys $INSERV -pwf $USERNAME"
# Note : connecting using the CLI requires creating password files (.pwf)

# To connect using SSH. uncomment the following line
CONNECTCOMMAND="ssh $USERNAME@$INSERV"
# Note : connecting using SSH requires setting public key authentication


#echo $INSERV $USERNAME $COMMAND >> $TMPDIR/3par_check_log.out

if [ $COMMAND == "check_pd" ]

then
$CONNECTCOMMAND showpd -showcols Id,State -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out 2>>$TMPDIR/log.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `grep -c failed $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! The following PDs have abnormal status : `grep -v normal $TMPDIR/3par_$COMMAND.$INSERV.out | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ `grep -c degraded $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! The following PDs have abnormal status : `grep -v normal $TMPDIR/3par_$COMMAND.$INSERV.out | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : All PDs have normal status

rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi


if [ $COMMAND == "check_node" ]
then
$CONNECTCOMMAND shownode -s -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `grep -c -i failed $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! The following nodes have abnormal status : `grep -i failed $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ `grep -c -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! The following nodes have abnormal status : `grep -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : All nodes have normal status
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi

if [ $COMMAND == "check_ps" ]
then
$CONNECTCOMMAND shownode -ps -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
RC=3
fi

if [ `grep -c -i failed $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! The following Node Power Supply have abnormal status : `grep -i failed $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=2
else
if [ `grep -c -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! The following Node Power Supply have abnormal status : `grep -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=1
else
echo OK : All Power Supply have normal status
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=0
fi
fi
fi

if [ $COMMAND == "check_ps_cage" ]
then
$CONNECTCOMMAND showcage -d > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
RC=3
fi

if [ `awk '{ if ($0 ~ "------Cage") cage=$5; if ($0 ~ "Failed") print cage" "$0}' $TMPDIR/3par_$COMMAND.$INSERV.out|wc -l` -gt 0 ]
then
echo CRITICAL! The following cages have abnormal status : `awk '{ if ($0 ~ "------Cage") cage=$5; if ($0 ~ "Failed") print cage" "$0}' $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=2
else
if [ `awk '{ if ($0 ~ "------Cage") cage=$5; if ($0 ~ "Degraded") print cage" "$0}' $TMPDIR/3par_$COMMAND.$INSERV.out|wc -l` -gt 0 ]
then
echo WARNING! The following cages have abnormal status : `awk '{ if ($0 ~ "------Cage") cage=$5; if ($0 ~ "Degraded") print cage" "$0}' $TMPDIR/3par_$COMMAND.$INSERV.out | tr -s " " | tr -d '\n'`
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=1
else
echo OK : All cages have normal status
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
RC=0
fi
fi
fi

if [ $COMMAND == "check_vv" ]
then
$CONNECTCOMMAND showvv -showcols Name,State -notree -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `grep -c -i failed $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! There are failed VVs. Contact 3PAR support
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ `grep -c -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! There are degraded VVs. Contact 3PAR support
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : All VVs are normal
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi


if [ $COMMAND == "check_ld" ]
then
$CONNECTCOMMAND showld -state -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `grep -c -i failed $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! There are failed LDs. Contact 3PAR support
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ `grep -c -i degraded $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! There are degraded LDs. Contact 3PAR support
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : All LDs have normal status
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi

if [ $COMMAND == "check_port_fc" ]
then
$CONNECTCOMMAND showport -nohdtot > $TMPDIR/3par_$COMMAND.$INSERV.out1
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi
grep -v -i iscsi $TMPDIR/3par_$COMMAND.$INSERV.out1 | grep -v -i rcip > $TMPDIR/3par_$COMMAND.$INSERV.out
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out1

if [ `grep -c -i error $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo CRITICAL! Some ports are in the error state
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ `grep -c -i loss_sync $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ] || [ `grep -c -i config_wait $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ] || [ `grep -c -i login_wait $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ] || [ `grep -c -i non_participate $TMPDIR/3par_$COMMAND.$INSERV.out` -gt 0 ]
then
echo WARNING! Some ports are in an abnormal state \(loss_sync, config_wait, login_wait or non_participate\)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : All FC ports have normal status \(ready or offline\)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi



if [ $COMMAND == "check_cap_fc" ]
then
$CONNECTCOMMAND showpd -p -devtype FC -showcols Size_MB,Free_MB -csvtable > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `tail -1 $TMPDIR/3par_$COMMAND.$INSERV.out` = "No PDs listed" ]
then
echo No FC disks
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi

TOTCAPFC=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f1`
FREECAPFC=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f2`
USEDCAPPCFC=`expr 100 \- \( \( $FREECAPFC \* 100 \) \/ $TOTCAPFC \)`

if [ $USEDCAPPCFC -ge $PCCRITICALFC ]
then
echo CRITICAL! Used FC capacity = $USEDCAPPCFC\% \( \> $PCCRITICALFC\% \)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ $USEDCAPPCFC -ge $PCWARNINGFC ]
then
echo WARNING! Used FC capacity = $USEDCAPPCFC\% \( \> $PCWARNINGFC\% \)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else

echo OK : Used FC capacity = $USEDCAPPCFC\%
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi

if [ $COMMAND == "check_cap_nl" ]
then
$CONNECTCOMMAND showpd -p -devtype NL -showcols Size_MB,Free_MB -csvtable > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

#if [ `tail -1 $TMPDIR/3par_$COMMAND.$INSERV.out` = "No PDs listed" ]
#then
#echo No NL disks
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 0
#fi

TOTCAPNL=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f1`
FREECAPNL=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f2`
#USEDCAPPCNL=`expr 100 \- \( \( $FREECAPNL \* 100 \) \/ $TOTCAPNL \)`

if [ $TOTCAPNL == 0 ]
then
echo "Total NL Disk Capacity = 0"
else
USEDCAPPCNL=`expr 100 \- \( \( $FREECAPNL \* 100 \) \/ $TOTCAPNL \)`
echo OK : Used NL capacity = $USEDCAPPCNL\%
fi


#if [ $USEDCAPPCNL -ge $PCCRITICALNL ]
#then
#echo CRITICAL! Used NL capacity = $USEDCAPPCNL\% \( \> $PCCRITICALNL\% \)
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 2
#else
#if [ $USEDCAPPCNL -ge $PCWARNINGNL ]
#then
#echo WARNING! Used NL capacity = $USEDCAPPCNL\% \( \> $PCWARNINGNL\% \)
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 1
#else
#echo OK : Used NL capacity = $USEDCAPPCNL\%
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 0
#fi
#fi
fi

##Implementation for SSD Disks

if [ $COMMAND == "check_cap_ssd" ]
then
$CONNECTCOMMAND showpd -p -devtype SSD -showcols Size_MB,Free_MB -csvtable > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to InServ $INSERV
exit 3
fi

if [ `tail -1 $TMPDIR/3par_$COMMAND.$INSERV.out` = "No PDs listed" ]
then
echo No SSD disks
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi

TOTCAPSSD=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f1`
FREECAPSSD=`cat ${TMPDIR}/3par_${COMMAND}.${INSERV}.out | tail -1 | cut -d, -f2`
USEDCAPPCSSD=`expr 100 \- \( \( $FREECAPSSD \* 100 \) \/ $TOTCAPSSD \)`

if [ $USEDCAPPCSSD -ge $PCCRITICALSSD ]
then
echo CRITICAL! Used SSD capacity = $USEDCAPPCSSD\% \( \> $PCCRITICALSSD\% \)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 2
else
if [ $USEDCAPPCSSD -ge $PCWARNINGSSD ]
then
echo WARNING! Used SSD capacity = $USEDCAPPCSSD\% \( \> $PCWARNINGSSD\% \)
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 1
else
echo OK : Used SSD capacity = $USEDCAPPCSSD\%
rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
exit 0
fi
fi
fi

if [ $COMMAND == "check_3par_volume" ]
then

$CONNECTCOMMAND showvv -csvtable | tail -n +3 | head -n -2 > $TMPDIR/3par_$COMMAND.$INSERV.out
if [ $? -gt 0 ]
then
echo Could not connect to 3PAR $INSERV
exit 3
fi


while IFS= read -r line
do
VMFS=$(echo $line | cut -d "," -f 2)
VSIZE=`echo $line | grep ${VMFS} | cut -d, -f12`
if [ $VSIZE == '--' ]
then
VSIZE=1
fi
VSIZE_Gb=`expr \( $VSIZE \/ 1024 \)`

USED=`echo $line | grep ${VMFS} | cut -d, -f11`
if [ $USED == '--' ]
then
USED=1
fi
USED_Gb=`expr \( $USED \/ 1024 \)`

FREE=`expr \( $VSIZE \- $USED \)`
FREE_Gb=`expr \( $FREE \/ 1024 \)`

FREEPERCENT=`expr 100 \- \( \( $USED \* 100 \) \/ $VSIZE \)`
USEDPERCENT=`expr 100 \- \( $FREEPERCENT \)`

WARNCRAW=$(($VSIZE*$WARNING/100))
WARNCRAW_Gb=`expr \( $WARNCRAW \/ 1024 \)`

CRITCCRAW=$(($VSIZE*$CRITICAL/100))
CRITCCRAW_Gb=`expr \( $CRITCCRAW \/ 1024 \)`


if [ $USED_Gb -ge $CRITCCRAW_Gb ]
then
echo $VMFS : CRITICAL! Total=$VSIZE_Gb\Gb\, Used=$USED_Gb\Gb\ \($USEDPERCENT%\), Free=$FREE_Gb\Gb\ \($FREEPERCENT%\), \Warning Limit Used :\ $WARNCRAW_Gb \Gb\, \Critical Limit Used :\ $CRITCCRAW_Gb\Gb
echo " "
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 2
else
if [ $USED_Gb -ge $WARNCRAW_Gb ]
then
echo $VMFS : WARNING! Total=$VSIZE_Gb\Gb\, Used=$USED_Gb\Gb\ \($USEDPERCENT%\), Free=$FREE_Gb\Gb\ \($FREEPERCENT%\), \Warning Limit Used :\ $WARNCRAW_Gb \Gb\, \Critical Limit Used :\ $CRITCCRAW_Gb\Gb
echo " "
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 1
else

echo $VMFS : OK : Total=$VSIZE_Gb\Gb\, Used=$USED_Gb\Gb\ \($USEDPERCENT%\), Free=$FREE_Gb\Gb\ \($FREEPERCENT%\), \Warning Limit     Used :\ $WARNCRAW_Gb \Gb\, \Critical Limit Used :\ $CRITCCRAW_Gb\Gb
echo " "
#rm -f $TMPDIR/3par_$COMMAND.$INSERV.out
#exit 0
fi
fi
done < "$TMPDIR/3par_$COMMAND.$INSERV.out"
fi

if [ $COMMAND == "check_pdspace" ]
  then
          $CONNECTCOMMAND showpd -space > $TMPDIR/3par_$COMMAND.$INSERV.out 2>>$TMPDIR/log.out
          cat $TMPDIR/3par_$COMMAND.$INSERV.out
fi

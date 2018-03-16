#!/bin/bash

WARN_TEMP=75.0
MAX_TEMP=80.0
DISASTER_TEMP=82.0
TIMESTAMP="`date +%Y%m%d%H%M%S`"
CPID=$$
F_LOG='/var/log/fallback.log'
F_SIZE=`du -b $F_LOG | cut -f 1`

CURRENT_TEMP=`/opt/vc/bin/vcgencmd measure_temp | tr -d "[a-zA-z,=,']"`

F_MONTH_OLD=`find /var/log/ -name fallback.log -type f -mtime +30 -exec ls {} \;`
IS_SIZE_G20M=`echo $(bc <<< "$F_SIZE >= 20971520")`
IS_NORMAL=`echo $(bc <<< "$CURRENT_TEMP < $WARN_TEMP")`
IS_GE_WARN=`echo $(bc <<< "$CURRENT_TEMP >= $WARN_TEMP")`
IS_LE_MAX=`echo $(bc <<< "$CURRENT_TEMP <= $MAX_TEMP")`
IS_GE_MAX=`echo $(bc <<< "$CURRENT_TEMP >= $MAX_TEMP")`
IS_LE_DISASTER=`echo $(bc <<< "$CURRENT_TEMP <= $DISASTER_TEMP")`

if [ ! -z "$F_MONTH_OLD" -o $IS_SIZE_G20M -eq 1 ]; then
     rm $F_LOG
else
     echo "$TIMESTAMP [$CPID] INFO : $F_LOG Size : $F_SIZE Bytes" >> $F_LOG
fi

if [ $IS_NORMAL -eq 1 ]; then
    echo "$TIMESTAMP [$CPID] INFO : Current temperature is $CURRENT_TEMP, Which is in operating temperature range. Nothing to do. EXITING...." >> $F_LOG
elif [ $IS_GE_WARN -eq 1 -o $IS_LE_MAX -eq 1 ]; then
    echo "$TIMESTAMP [$CPID] WARN : Current temperature is $CURRENT_TEMP, Which is above warning level. If temperature did not drop. Your Pi will be restarted." >> $F_LOG
elif [ $IS_GE_MAX -eq 1 -o $IS_LE_DISASTER -eq 1 ]; then
    echo "$TIMESTAMP [$CPID] ERROR : Current temperature is $CURRENT_TEMP, Which is above operating limit. Restarting your Pi......." >> $F_LOG
    reboot
else
    echo "$TIMESTAMP [$CPID] CRITICAL : Current temperature is $CURRENT_TEMP, Which is a disaster and You're FUCKED....Initiating Shutdown......" >> $F_LOG
    shutdown
fi

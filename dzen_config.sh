#!/bin/bash
# ============================================
# by TJ Koblentz
# --------------------------------------------
# INFLUENCED BY
#
# - VOLUME [amixer|gdbar] (c) 2007 Tom Rauchenwald and Jochen Schweizer
# - NETWORK               (c) 2007 Robert Manea and Christian Dietrich
# - BATTERY               lyon8 (lyon8@gmx.net)
# --------------------------------------------
# REQUIREMENTS
#
# - alsamixer, wmctrl, TODO
# ============================================

# TODO track X in global so widget position is dynamic
Y=0
HOME=/home/tj

# when we fork -- two processes are spawned but `jobs -p` returns half
# pgrep is an ugly(?) workaround
# TODO one extra pid is killed when it shouldn't...
clean_up() {
  # for pid in `jobs -p`
  for pid in `pgrep -f '/bin/bash ./dzen_config.sh'`
  do
    kill $pid
  done
  exit 0
}

trap clean_up SIGHUP SIGINT SIGTERM

# ============================================
# GLOBAL CONFIG OPTIONS
# ============================================
SLEEP_TIME=1  # in seconds
# --------------------------------------------
BG='#000'     # background
FG='#999'     # foreground
FN='fixed'    # font
# --------------------------------------------
GBG='#333'    # color of gauge backgrounds
GFG='#a8a3f5' # color of gauges
GH=7          # height of gauges
GW=50         # width of gauges
# --------------------------------------------
FBG=$GBG # '#f0dfaf' # color of focus backgrounds
FFG=$GFG # '#1e2329' # color of focus foregrounds

# ============================================
# WIDGET DEFINITIONS
# ============================================
datetime() {
  X=0
  W=190
  while : ; do
    # echo -n "$ICON "
    echo `date`
    sleep $SLEEP_TIME
  done | dzen2 -ta c -tw $W -x $X -y $Y -fn $FN -fg $FG -bg $BG
}

workspaces() {
  # X=`expr $X + $W`
  X=190
  W=340
  while : ; do
    # thx to comment @ http://dzen.geekmode.org/dwiki/doku.php?id=dzen:dzen-and-xmonad
    DESKTOPS=`wmctrl -d | cut -d\   -f13`
    line=""
    for d in $DESKTOPS
    do
      switchTo=`wmctrl -d | grep $d | cut -d\  -f1`
      if [[ -z "`wmctrl -d | grep $d | grep '*'`" ]]
      then
        # line+="^ca(1,$HOME/bar.sh $switchTo)$d^ca()"
        line+="$d  "
      else
        # line+="^ca(1,$HOME/bar.sh $switchTo)^bg($FBG)^fg($FFG)$d^fg()^bg()^ca()"
        # echo -n "^bg($FBG)^fg($FFG)$d^fg()^bg()" ' '
        line+="^bg($FBG)^fg($FFG)$d^fg()^bg() "
        # line+="[ $d ] "
      fi
    done
    echo $line
    sleep 0.1 # need fast response time! =]
  done | dzen2 -ta c -tw $W -x $X -y $Y  -fg $FG -bg $BG -fn $FN
}

# TODO make mute icon show up if 0% volume
sound() {
  # X=`expr $X + $W`
  X=530
  W=470
  ICON="^i($HOME/.dzen/icons/dzen_xbm_pack/vol-hi.xbm)"
  # command to increase the volume
  CI="amixer -c0 sset PCM 5dB+ >/dev/null"
  #CI="aumix -v +5"
  # command to decrease the volume
  CD="amixer -c0 sset PCM 5dB- >/dev/null"
  #CD="aumix -v -5
  # command to pipe into gdbar to display the gauge
  # should print out 2 space-seperated values, the first is the current
  # volume, the second the maximum volume
  MAX=`amixer -c0 get PCM | awk '/^  Limits/ { print $5 }'`
  #MAX=100
  CV="amixer -c0 get PCM | awk '/^  Front Left/ { print \$4 \" \" $MAX }'"
  #CV="aumix -q | line | cut -d \" \" -f 3"
  while : ; do
    echo -n "$ICON  "
    eval $CV | gdbar -nonl -h $GH -w $GW -fg $GFG -bg $GBG
    echo `mpc | head -n 1`
    sleep $SLEEP_TIME
  done | dzen2 -ta c -tw $W -x $X -y $Y\
    -fn $FN -fg $FG -bg $BG -e "button3=exit;button4=exec:$CI;button5=exec:$CD"
}

network() {
  X=1000
  W=420
  # Here we remember the previous rx/tx counts
  WRXB=`cat /sys/class/net/wlan0/statistics/rx_bytes`
  WTXB=`cat /sys/class/net/wlan0/statistics/tx_bytes`
  ERXB=`cat /sys/class/net/eth0/statistics/rx_bytes`
  ETXB=`cat /sys/class/net/eth0/statistics/tx_bytes`
  ICON="^i($HOME/.dzen/icons/dzen_xbm_pack/net-wifi4.xbm)"
  ARROW_UP="^i($HOME/.dzen/icons/dzen_bitmaps/arr_up.xbm)"
  ARROW_DOWN="^i($HOME/.dzen/icons/dzen_bitmaps/arr_down.xbm)"
  while : ; do
    echo -n "$ICON "
    WLAN0_UP_DOWN=`ip link | grep wlan0 | awk '{print $9}'`
    ETH0_UP_DOWN=`ip link | grep eth0 | awk '{print $9}'`
    WRXBN=`cat /sys/class/net/wlan0/statistics/rx_bytes`
    WTXBN=`cat /sys/class/net/wlan0/statistics/tx_bytes`
    WRXR=$(printf "%4d kB/s" $(echo "($WRXBN - $WRXB) / 1024/${SLEEP_TIME}" | bc))
    WTXR=$(printf "%4d kB/s" $(echo "($WTXBN - $WTXB) / 1024/${SLEEP_TIME}" | bc))
    ERXBN=`cat /sys/class/net/eth0/statistics/rx_bytes`
    ETXBN=`cat /sys/class/net/eth0/statistics/tx_bytes`
    ERXR=$(printf "%4d kB/s" $(echo "($ERXBN - $ERXB) / 1024/${SLEEP_TIME}" | bc))
    ETXR=$(printf "%4d kB/s" $(echo "($ETXBN - $ETXB) / 1024/${SLEEP_TIME}" | bc))
    # WLAN0
    if [ $WLAN0_UP_DOWN = UP ]; then
      echo -n "^bg($FBG)^fg($FFG)wlan0^fg()^bg() "
    fi
    echo -n "wlan0 "
    echo -n "^fg(orange3)$ARROW_DOWN^fg()"
    echo -n "$WRXR"
    echo -n "^fg(#80AA83)^p(3)$ARROW_UP^fg($FG)"
    echo -n "$WTXR "
    # ETH0
    if [ $ETH0_UP_DOWN = UP ]; then
      echo -n "^bg($FBG)^fg($FFG)eth0^fg()^bg() "
    fi
    echo -n "eth0 "
    echo -n "^fg(orange3)$ARROW_DOWN^fg()"
    echo -n "$ERXR"
    echo -n "^fg(#80AA83)^p(3)$ARROW_UP^fg($FG)"
    echo "$ETXR"
    WRXB=$WRXBN; WTXB=$WTXBN
    ERXB=$ERXBN; ETXB=$ETXBN
    sleep $SLEEP_TIME
  done | dzen2 -ta c -tw $W -x $X -y $Y  -fg $FG -bg $BG -fn $FN
}

# TODO improve this for less 0% and to know when plugged in better!!
battery() {
  # X=`expr $X + $W`
  X=1420
  W=180
  LOWBAT=25        # percentage of battery life marked as low
  LOWCOL='#ff4747' # color when battery is low
  while : ; do
    BATT="/sys/class/power_supply/BAT0"
    STATUS=`cat $BATT/status`
    REMAINING=`acpi | sed -ne '/%, / s/.*%, \([0-9:]*\).*/\1/p'`
    if [ $STATUS = 'Charging' ]; then
      ICON="^i($HOME/.dzen/icons/dzen_xbm_pack/power-ac.xbm)" # caption (also icons are possible)
   else
      ICON="^i($HOME/.dzen/icons/dzen_xbm_pack/power-bat2.xbm)" # caption (also icons are possible)
    fi
    BAT_FULL=`cat $BATT/charge_full`
    RCAP=`cat $BATT/charge_now`
    RPERCT=`expr $RCAP \* 100`
    RPERC=`expr $RPERCT / $BAT_FULL`
    if [ $RPERC -le $LOWBAT ]; then
      GFG=$LOWCOL
    fi
    echo -n "$ICON "
    echo -n $REMAINING
    eval echo $RPERC | gdbar -h $GH -w $GW -fg $GFG -bg $GBG
    sleep $SLEEP_TIME
  done | dzen2 -ta c -tw $W -x $X -y $Y  -fg $FG -bg $BG -fn $FN
}

# ============================================
# RUN WIDGETS
# ============================================
i=0
for widget in datetime workspaces sound network battery
do
  $widget > /dev/null 2> /dev/null &
  PIDS[$i]=$!
  i=`expr $i + 1`
done

wait

clean_up

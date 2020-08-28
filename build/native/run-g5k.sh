#!/usr/bin/env bash

NAS_BIN=/home/mserpa/public/NPB3.3-OMP-gcc4.8/bin/
BIN=/tmp

cp $NAS_BIN/* $BIN

HOST=`hostname | awk -F. {'print $1'}`
ARCH=`gcc -march=native -Q --help=target | grep march | awk '{print $2}'`

if [ "$HOST" == "chifflot-1" ]; then
  PREF="native-L1-L2"
elif [ "$HOST" == "chifflot-2" ]; then
  PREF="native-L1-L2"
elif [ "$HOST" == "chifflot-3" ]; then
  PREF="native-L1"
elif [ "$HOST" == "chifflot-4" ]; then
  PREF="native-L1"
elif [ "$HOST" == "chifflot-5" ]; then
  PREF="native-L2"
elif [ "$HOST" == "chifflot-6" ]; then
  PREF="native-L2"
elif [ "$HOST" == "chifflot-7" ]; then
  PREF="native-none"
elif [ "$HOST" == "chifflot-8" ]; then
  PREF="native-none"
else
  PREF="unknown"
fi

date +"%d/%m/%Y %H:%M:%S"
printf "\t Running on $ARCH@$HOST \n\n"

unset -v KMP_AFFINITY
unset -v GOMP_CPU_AFFINITY
unset -v OMP_NUM_THREADS
unset -v OMP_SCHEDULE
unset -v LD_PRELOAD
unset -v PAPI_EVENT
unset -v OMP_WAIT_POLICY

export OMP_WAIT_POLICY=ACTIVE

CORES=`lscpu | grep "^CPU(s):" | awk {'print $2'}`
export GOMP_CPU_AFFINITY="0-$CORES"

DOE=./DoE/$HOST.nas.csv
mkdir -p tload_output

while true; do
  STEP=`ls tload_output/ | grep $HOST | sed "s/$HOST.//g" | sed "s/.nas.csv//g" | sort -n | tail -n1`
  if [ -z "$STEP" ]; then
    STEP=0
  fi
 
  if [ -f "$DOE" ]; then
    printf "\t Using old $DOE\n\n"
  else 
    ./DoE.sh nas
    STEP=$((STEP+1))
  fi

  OUTPUT=./tload_output/$HOST.$STEP.nas.csv

  date +"%d/%m/%Y %H:%M:%S"
  printf "\t Step: $STEP \n\n"

  while IFS=\; read -r APP THREADS METRIC SIZE; do



    date +"%d/%m/%Y %H:%M:%S"
    printf "\t Warm-up\n\n"
    stress-ng --cpu 100 -t 5 &> /tmp/time.stress
    sleep 1
    sed 's/^/\t/' /tmp/time.stress
    printf "\n"

    date +"%d/%m/%Y %H:%M:%S"
    printf "\t Application: $APP.$SIZE  \n"
    printf "\t Threads: $THREADS \n"
    printf "\t Event: $METRIC \n"


    export OMP_NUM_THREADS=$THREADS
    export PAPI_COUNTER_LIST=$METRIC

    EXEC=$BIN/$APP.$SIZE.x
    
    printf "\t Start: `date +"%d/%m/%Y %H:%M:%S"` \n"
    LD_PRELOAD=/home/mserpa/public/thread-load/libtloadpapi.so numactl --membind=0 --cpunodebind=0 $EXEC &> /tmp/exec
    printf "\t End:   `date +"%d/%m/%Y %H:%M:%S"` \n\n"

    grep "statistic of thread" /tmp/exec | grep $METRIC | awk '{print $NF}' > /tmp/papi
  
    METRIC_NAME=`echo $METRIC | sed 's/\./-/g' | sed 's/\_/-/g' | sed 's/\:/-/g'`
    for CPU in `seq 0 $((THREADS - 1))`; do
      VALUE=`sed -n "$((CPU + 1))"p /tmp/papi`
      echo native-$PREF,$APP,$SIZE,$CPU,$THREADS,$METRIC_NAME,$VALUE >> $OUTPUT
    done

    sed -i '1d' $DOE
    find $DOE -size 0 -delete
  done < $DOE

done

date +"%d/%m/%Y %H:%M:%S"
printf "\t done\n\n"
#!/usr/bin/env bash
#SBATCH --time=24:00:00
#SBATCH --partition=cei
#SBATCH --exclusive
#SBATCH --job-name=CCPE-ROD

ROD_BIN=$HOME/rodinia/rodinia/
BIN=/tmp

cp $ROD_BIN/* $BIN

HOST=`hostname | awk -F. {'print $1'}`
ARCH=`gcc -march=native -Q --help=target | grep march | awk '{print $2}'`

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

DOE=./DoE_rod/$HOST.rod.csv
mkdir -p rod_output

while true; do
  STEP=`ls rod_output/ | grep $HOST | sed "s/$HOST.//g" | sed "s/.rod.csv//g" | sort -n | tail -n1`
  if [ -z "$STEP" ]; then
    STEP=0
  fi
 
  if [ -f "$DOE" ]; then
    printf "\t Using old $DOE\n\n"
  else 
    ./DoE_rod.sh rod
    STEP=$((STEP+1))
  fi

  OUTPUT=./rod_output/$HOST.$STEP.rod.csv
  echo version,app,size,cpu,threads,metric,value >> $OUTPUT 

  date +"%d/%m/%Y %H:%M:%S"
  printf "\t Step: $STEP \n\n"

  while IFS=\; read -r APP THREADS METRIC SIZE PREF; do

    date +"%d/%m/%Y %H:%M:%S"
    printf "\t Warm-up\n\n"
    stress-ng --cpu 100 -t 5 &> /tmp/time.stress
    sleep 1
    sed 's/^/\t/' /tmp/time.stress
    printf "\n"

    date +"%d/%m/%Y %H:%M:%S"
    printf "\t Application: $APP $SIZE  \n"
    printf "\t Threads: $THREADS \n"
    printf "\t Event: $METRIC \n"
    printf "\t Prefetchers: $PREF \n"

    export OMP_NUM_THREADS=$THREADS
    export PAPI_COUNTER_LIST=$METRIC

    # PREFETCHERS CONFIGURATION:
    # --prefetch 0  -> enables all prefetchers (L1-L2)
    # --prefetch 3  -> enables all L1 prefetchers
    # --prefetch 12 -> enables all L2 prefetchers
    # --prefetch 15 -> disables all prefetchers
    if [[ "$PREF" == "L1-L2" ]]; then
      $SCRATCH/utils --prefetch 0      
    else 
      if [[ "$PREF" == "L1" ]]; then
        $SCRATCH/utils --prefetch 3
      else
        if [[ "$PREF" == "L2" ]]; then
          $SCRATCH/utils --prefetch 12
        else
          if [[ "$PREF" == "none" ]]; then
            $SCRATCH/utils --prefetch 15
          fi
        fi
      fi
    fi
    $SCRATCH/utils --turbo-off &>> /tmp/turbo

    EXEC=$BIN/$APP

    printf "\t Start: `date +"%d/%m/%Y %H:%M:%S"` \n"
    LD_PRELOAD=$HOME/cmp270/thread-load/libtloadpapi.so numactl --membind=0 --cpunodebind=0 $EXEC $SIZE &> /tmp/exec
    printf "\t End:   `date +"%d/%m/%Y %H:%M:%S"` \n\n"

    $SCRATCH/utils --turbo-on &>> /tmp/turbo
    # Reactivate all prefetchers after the execution is done
    $SCRATCH/utils --prefetch 0      

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

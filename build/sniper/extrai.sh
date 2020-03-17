#!/usr/bin/env bash

version=$2
app=$3
threads=`grep "ncores" $1 | tr -d ' ' | awk -F= {'print $2'}`

for th in `seq 1 $threads`; do
  INSTRUCTIONS=`cat $1 | grep "core.instructions =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  IPC=`cat $1 | grep "ipc =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  CYCLES=$(echo "${INSTRUCTIONS} / ${IPC}" | bc )

  echo $version,$app,$(($th-1)),$threads,instructions,$INSTRUCTIONS
  echo $version,$app,$(($th-1)),$threads,ipc,$IPC
  echo $version,$app,$(($th-1)),$threads,cycles,$CYCLES

  LOADS=`cat $1 | grep "L2.loads =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  MISSES=`cat $1 | grep "L2.load-misses =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  HITS=$(echo "${LOADS} - ${MISSES}" | bc )

  echo $version,$app,$(($th-1)),$threads,l2-rqsts-demand-data-rd-all,$LOADS
  echo $version,$app,$(($th-1)),$threads,l2-rqsts-demand-data-rd-miss,$MISSES
  echo $version,$app,$(($th-1)),$threads,l2-rqsts-demand-data-rd-hit,$HITS
  
  PREFETCHES=`cat $1 | grep "L2.prefetches =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  P_HITS=`cat $1 | grep "L2.hits-prefetch =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`
  P_MISSES=$(echo "${PREFETCHES} - ${P_HITS}" | bc )
  P_EVICT=`cat $1 | grep "L2.evict-prefetch =" | tr -d ' ' |  awk -F= {'print $2'} | cut -d , -f $th`

  echo $version,$app,$(($th-1)),$threads,l2_rqsts-all-pf,$PREFETCHES
  echo $version,$app,$(($th-1)),$threads,l2_rqsts-pf-hit,$P_HITS
  echo $version,$app,$(($th-1)),$threads,l2_rqsts-pf-miss,$P_MISSES
  echo $version,$app,$(($th-1)),$threads,l2-lines-out-useless-pref,$P_EVICT

  cp $1 $1.bkp
done
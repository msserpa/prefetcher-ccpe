#!/usr/bin/env bash

cpuMetrics=(cycles instrs)
cacheMetrics=(hGETS hGETX mGETS mGETXIM mGETXSM)
# somar Hs e Ms

# cycles
# instructions
# l2-lines-out-useless-hwpf
# l2-rqsts-pf-miss
# l2-rqsts-all-pf
# l2-lines-out-useless-hwpf
# ** l2_rqsts.demand_data_rd_hit
# ** l2_rqsts.demand_data_rd_miss

app=$2
threads=`grep "thCr" $1 | awk {'print $2'}`

for th in `seq 0 $(($threads-1))`; do
  # grep for each CPU-th (the output is for CPU)
  VAR=$(cat $1 | grep -i -A 7 " CPU-$th:" > /tmp/zsimout)

  VALUE=`cat /tmp/zsimout | grep " cycles" | awk {'print $2'}`
  echo zsim,$app,$th,$threads,cycles,$VALUE

  VALUE=`cat /tmp/zsimout | grep " instrs" | awk {'print $2'}`
  echo zsim,$app,$th,$threads,instructions,$VALUE

  # grep for each l2 caches (one for CPU)
  VAR=$(cat $1 | grep -i -A 12 " l2_CPU-$th:" > /tmp/zsimout)
  
  hGETS=`cat /tmp/zsimout | grep " hGETS" | awk {'print $2'}`
  hGETX=`cat /tmp/zsimout | grep " hGETX" | awk {'print $2'}`
  mGETS=`cat /tmp/zsimout | grep " mGETS" | awk {'print $2'}`
  mGETXIM=`cat /tmp/zsimout | grep " mGETXIM" | awk {'print $2'}`
  mGETXSM=`cat /tmp/zsimout | grep " mGETXSM" | awk {'print $2'}`

  VALUE1=$(echo "${hGETS} + ${hGETX}" | bc )
  VALUE2=$(echo "${mGETS} + ${mGETXIM} + ${mGETXSM}" | bc )

  echo zsim,$app,$th,$threads,l2-rqsts-demand-data-rd-hit,$VALUE1
  echo zsim,$app,$th,$threads,l2-rqsts-demand-data-rd-miss,$VALUE2

  cp $1 $1.bkp
done

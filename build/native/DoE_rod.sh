#!/usr/bin/env bash

if [ $# -lt 1 ]; then
  echo "Usage : $0 <benchmark>"
  exit 1
fi

mkdir -p DoE_rod

if [ "$1" == "spec" ]; then
  declare -a APP=("applu331" "botsalgn" "botsspar" "bt331" "bwaves" "fma3d" "ilbdc" "imagick" "kdtree" "md" "mgrid331" "nab" "smithwa" "swim")
  OUTPUT=./DoE/`hostname | awk -F. {'print $1'}`.spec.csv
else
  if [ "$1" == "nas" ]; then
    #declare -a APP=("bt" "cg" "ep" "ft" "is" "lu" "mg" "sp" "ua")
    declare -a APP=("cg")
    OUTPUT=./DoE/`hostname | awk -F. {'print $1'}`.nas.csv
  else
    declare -a APP=("backprop")
    OUTPUT=./DoE_rod/`hostname | awk -F. {'print $1'}`.rod.csv
  fi
  fi

#declare -a SIZE=("W" "A" "B")
declare -a SIZE=("1048576" "4194304" "16777216")
declare -a THREADS=("1" "2" "4" "8" "12")
declare -a METRICS=("PAPI_TOT_INS" "PAPI_TOT_CYC" "PAPI_TOT_CYC" "PAPI_TOT_INS" "L2_RQSTS:DEMAND_DATA_RD_HIT" "L2_RQSTS:DEMAND_DATA_RD_MISS" "L2_RQSTS:ALL_PF" "L2_RQSTS:PF_HIT" "L2_RQSTS:PF_MISS" "L2_LINES_OUT:USELESS_HWPREF" "L2_LINES_OUT:USELESS_HWPF" "OFFCORE_RESPONSE_0:PF_L2_DATA_RD:ANY_RESPONSE" "OFFCORE_RESPONSE_0:PF_L2_DATA_RD:L3_HIT:SNP_ANY" "OFFCORE_RESPONSE_0:PF_L2_DATA_RD:L3_HIT:SNP_HITM" "OFFCORE_RESPONSE_0:PF_L2_RFO:ANY_RESPONSE" "OFFCORE_RESPONSE_0:PF_L2_RFO:L3_HIT:SNP_ANY" "OFFCORE_RESPONSE_0:PF_L2_RFO:L3_HIT:SNP_HITM" "OFFCORE_REQUESTS:DEMAND_DATA_RD" "OFFCORE_REQUESTS:ALL_DATA_RD" "OFFCORE_REQUESTS.L3_MISS_DEMAND_DATA_RD")
#declare -a METRICS=("MEM_LOAD_L3_HIT_RETIRED.XSNP_MISS" "MEM_LOAD_L3_HIT_RETIRED.XSNP_HIT" "MEM_LOAD_L3_HIT_RETIRED.XSNP_HITM" "MEM_LOAD_L3_HIT_RETIRED.XSNP_NONE")
declare -a PREFETCHERS=("L1-L2" "L1" "L2" "none")

rm -f $OUTPUT

for application in "${APP[@]}"; do
  for cpus in "${THREADS[@]}"; do
    for event in "${METRICS[@]}"; do
      for size in "${SIZE[@]}"; do
        for pref in "${PREFETCHERS[@]}"; do
          echo "$application;$cpus;$event;$size;$pref" >> $OUTPUT
        done 
      done
    done
  done
done


for i in `seq 1 30`; do
  shuf $OUTPUT -o $OUTPUT
done

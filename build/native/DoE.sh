#!/usr/bin/env bash

if [ $# -lt 1 ]; then
	echo "Usage : $0 <benchmark>"
	exit 1
fi

if [ "$1" == "spec" ]; then
	declare -a APP=("applu331" "botsalgn" "botsspar" "bt331" "bwaves" "fma3d" "ilbdc" "imagick" "kdtree" "md" "mgrid331" "nab" "smithwa" "swim")
	OUTPUT=./DoE/`hostname | awk -F. {'print $1'}`.spec.csv
else
	declare -a APP=("bt" "cg" "ep" "ft" "is" "lu" "mg" "sp" "ua")
	OUTPUT=./DoE/`hostname | awk -F. {'print $1'}`.nas.csv
fi

declare -a SIZE=("W" "A")
declare -a THREADS=("1" "2" "4" "8" "12")
declare -a METRICS=("cycles" "instructions" "l2_rqsts.demand_data_rd_hit" "l2_rqsts.demand_data_rd_miss" "l2_rqsts.all_pf" "l2_rqsts.pf_hit" "l2_rqsts.pf_miss" "l2_lines_out.useless_hwpf" "l2_lines_out.useless_pref" "offcore_response.pf_l2_data_rd.any_response" "offcore_response.pf_l2_data_rd.l3_hit.any_snoop" "offcore_response.pf_l2_data_rd.l3_hit.hitm_other_core" "offcore_response.pf_l2_rfo.any_response" "offcore_response.pf_l2_rfo.l3_hit.any_snoop" "offcore_response.pf_l2_rfo.l3_hit.hitm_other_core" "offcore_requests.demand_data_rd" "offcore_requests.all_data_rd")


rm -f $OUTPUT


for application in "${APP[@]}"; do
	for cpus in "${THREADS[@]}"; do
    for event in "${METRICS[@]}"; do
      for size in "${SIZE[@]}"; do
        echo "$application;$cpus;$event;$size" >> $OUTPUT
      done
		done
	done
done


for i in `seq 1 10`; do
	shuf $OUTPUT -o $OUTPUT
done

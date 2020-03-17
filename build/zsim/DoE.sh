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

declare -a THREADS=("1" "2" "4" "8" "12")


rm -f $OUTPUT

SIZE=0
for application in "${APP[@]}"; do
	for cpus in "${THREADS[@]}"; do
			echo "$application;$cpus" >> $OUTPUT
			size=$((size+1))
	done
done

printf "\tcreating full factorial with $size runs ...\n"

for i in `seq 1 10`; do
	shuf $OUTPUT -o $OUTPUT
done

#!/bin/bash
#
# run_all_builds.sh [start-stage-num]
# 
# Run all the samba cross compiling scripts in order.
#
# Optionally specify a starting stage number.
#
# Only run this if you're confident that the
# scripts will work. Run them individually in
# the correc order on the first attempt.
#

start_stage=$1
SECONDS=0
current_stage=0

checkerr()
{
    if [ $? -ne 0 ]; then
	echo " Failure at stage $current_stage : $script_name  "
	echo " Fix problems and re-commence stage with "
	echo " $0 $current_stage "
	exit 1
    fi
}

for script_name in build-samba*.sh
do
    let current_stage++
    if [[ $current_stage -ge $start_stage ]]; then	   
	echo Running stage $current_stage : $script_name
	./$script_name
	checkerr
    fi
done
echo Finished. Total build took $SECONDS seconds



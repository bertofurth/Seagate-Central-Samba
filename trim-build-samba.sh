#!/bin/bash
#
# trim_build.sh
#
# Strip binaries in the "cross" subdirecory and delete
# pretty much everything that can be in order to just
# allow the tool to run on the target.
#
# Manually modify this script if you don't want to
# perform one of the stages.
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

BEFORE=$(du -s cross/ | cut -f1)

let current_stage++
echo Running stage $current_stage : Delete static libraries
find cross/ -name "*.a" -exec rm {} \; &> /dev/null
checkerr

let current_stage++
echo Running stage $current_stage : Delete documentation
rm -rf cross/usr/local/share/doc \
   cross/usr/local/share/man \
   cross/usr/local/share/info
checkerr

let current_stage++
echo Running stage $current_stage : Delete language locale files
rm -rf cross/usr/local/share/locale
checkerr

let current_stage++
echo Running stage $current_stage : Delete header files
rm -rf cross/usr/local/share/locale
checkerr

let current_stage++
echo Running stage $current_stage : Strip binaries
find cross/ -type f -exec strip {} \;  &> /dev/null
checkerr

let current_stage++
echo Running stage $current_stage : Remove unneeded directories
rm -rf cross/var ;  &> /dev/null
rm -rf cross/etc ;  &> /dev/null
checkerr

AFTER=$(du -s cross/ | cut -f1)
echo Finished. Bytes before - $BEFORE  Bytes after - $AFTER




#!/bin/bash
#
# Run all the samba cross compiling scripts in order.
#
# Only run this if you're confident that the
# scripts will work. Run them individually on
# the first attempt.
#
checkerr()
{
    if [ $? -ne 0 ]; then
	echo "Failure. Aborting "
	exit 1
    fi
}

for script_name in build-samba*.sh
do
    echo Running $script_name
    ./$script_name
done




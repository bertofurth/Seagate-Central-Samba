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

foreach script_name ( $(ls build-samba*.sh) )
./$script_name
checkerr
end



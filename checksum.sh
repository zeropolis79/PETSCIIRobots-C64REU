#!/bin/sh
#
LIST=$(ls *-64x)

status=0

for f in $LIST
do
    NEWSUM=$(md5sum $f)
    OLDSUM=$(grep " ${f}\$" original/checksums.txt)
    if [ "$NEWSUM" != "$OLDSUM" ]; then
        echo ERROR: $f MISMATCH:
        echo NEWSUM=$NEWSUM
        echo OLDSUM=$OLDSUM
        status=1
    fi
done
if [ "$status" = "0" ]; then
    echo "All file checksums match the original distribution."
fi
exit $status

#!/bin/bash

for i in *.csv;
do x=$(echo $i | grep '_' | sed 's/_/\-/g');
if [ -n "$x" ];
then mv $i $x;
fi;
done;

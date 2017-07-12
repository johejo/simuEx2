#!/bin/sh
for j in `seq 1 10`
do
    for i in `seq 1 20`
    do
        ns exp1.tcl $i > thp.txt
        cat thp.txt | python sum.py >> thpsum$i.txt
        cat thp.txt | python ave.py >> thpave$i.txt
    done
done

./paste.sh
./clean.sh

for i in `seq 1 20`
do
    cat thpsum$i.txt | python ave.py >> thpsumave.txt
    cat thpave$i.txt | python ave.py >> thpaveave.txt
    cat thpave$i.txt | python stdev.py >> thpstdev.txt
done

for i in `seq 1 20`
do
    echo $i
done > 1-20.txt
paste 1-20.txt thpsumave.txt > plotsum.txt
paste 1-20.txt thpaveave.txt > plotave.txt
paste 1-20.txt thpstdev.txt > plotstdev.txt

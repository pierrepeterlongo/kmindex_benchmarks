echo "== We have list.txt that gives the list of subjects and their metadata as TAB separated columns =="
echo "== First two columns are for <runID> <SubjectID> followed by metadata fields =="
rm -rf harvest/ verify/ merge/ index/ database/

perl -e '{print "\n===> Starting harvesting kmers: "}' 
date 

mkdir harvest

while read file; do
        base_file=$(basename $file .fastq.gz)
        echo ${base_file}
    	zcat $file | ./pebblescout_v2.25/software/pebblescout/harvester25 -o harvest/${base_file}  2>> /dev/null
done < fof.txt

perl -e '{print "\n===> Starting harvesting verification: "}' 
date 

mkdir verify

while read file; do
        base_file=$(basename $file .fastq.gz)
        echo ${base_file}
    	zcat $file | ./pebblescout_v2.25/software/pebblescout/harvester25 -o verify/${base_file} -c T  2>> /dev/null
done < fof.txt

grep '^' harvest/*.countsall | cut -d '/' -f 2- > tmp.orig
grep '^' verify/*.countsall | cut -d '/' -f 2- > tmp.check
diff tmp.orig tmp.check | wc | gawk '{if($1==0){printf("All good with harvesting\n")}else{printf("Verification failed for %d subjects\n",$1)}}'

perl -e '{print "\n===> Starting merge: "}' 
date 

mkdir merge
./pebblescout_v2.25/software/pebblescout/pebbletools.py -t prepare4firstMerge -i list.txt -f "harvest/*countsall" 
./pebblescout_v2.25/software/pebblescout/pebbletools.py -t performMerge -d merge -o joined -f "harvest/*counts"  

perl -e '{print "\n===> Starting main index build: "}' 
date 
mkdir index
./pebblescout_v2.25/software/pebblescout/pebbletools.py -t buildMainIndex -d index -f "merge/*gz" 

perl -e '{print "\n===> Starting top index build: "}' 
date 

mkdir database
./pebblescout_v2.25/software/pebblescout/pebbletools.py -t buildTopIndex -d database -f "index/IDX???/IDX???.idx" -s /home/symbiose/ppeterlo/.conda/envs/env_pebblescout/bin/sqlite3

perl -e '{print "\n===> Starting vocabulary build: "}' 
date 

./pebblescout_v2.25/software/pebblescout/pebbletools.py -t buildVocab -o db.vocab -F "3,4,5" -p offsets.tab -m list.txt 
find . -name "IDX???.idx" | xargs -I SOMEFILE -t -n 1 -P 16 ./pebblescout_v2.25/software/pebblescout/pscpretranslate -o SOMEFILE.tr.bin -f SOMEFILE -p offsets.tab 
find . -name "IDX???.idx.tr.bin" | xargs -I SOMEFILE -n 1  mv SOMEFILE database/ 

perl -e '{print "\n===> Starting vocabulary build with suppressed runs: "}' 
date 

./pebblescout_v2.25/software/pebblescout/pebbletools.py -t buildVocab -o db.with_suppressed.vocab -F "3,4,5" -p offsets.with_suppressed.tab -m list.txt -s suppressed.txt 
find . -name "IDX???.idx" | xargs -I SOMEFILE -t -n 1 -P 16 ./pebblescout_v2.25/software/pebblescout/pscpretranslate -o SOMEFILE.with_suppressed.tr.bin -f SOMEFILE -p offsets.with_suppressed.tab 
find . -name "IDX???.idx.with_suppressed.tr.bin" | xargs -I SOMEFILE -n 1  mv SOMEFILE database/ 

perl -e '{print "\n===> All done: "}' 
date 

echo "Please build json files manually using the samples provided"
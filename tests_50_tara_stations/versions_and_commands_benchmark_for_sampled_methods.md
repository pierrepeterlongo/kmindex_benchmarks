Despite this is not the primary goal of the kmindex manuscript, for curiosity purposes, we provide here the versions and commands used to run the benchmark for the sampled methods, based on the use of sketches for indexing data. 

Needle was able to build an index. However, query results suffer from a high false positive rate (24.2% on average, and up to 64.88% for some queries), and from a high false negative rate (19.27% on average).

<!-- vscode-markdown-toc -->
* [ Needle commands](#Needlecommands)
	* [ Needle indexing](#Needleindexing)
	* [ Needle query](#Needlequery)
* [ PebbleScout commands](#PebbleScoutcommands)
	* [ PebbleScout build](#PebbleScoutbuild)
	* [ PebbleScout expected query](#PebbleScoutexpectedquery)

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


### <a name='Needlecommands'></a> Needle commands

**(These results are not included in the kmindex manuscript)**

* Tool versions:
    Last update: 
    needle-ibf version: 
    SeqAn version: 3.2.0

#### <a name='Needleindexing'></a> Needle indexing

```bash
ls -dD data_per_station/* > fof.lst
./needle minimiser fof.lst -k 25 -t 32 --cutoff 2  
./needle ibfmin *.minimiser -t 32 -f 0.25 -e 2 -e 4 -e 8 -e 16 -e 32 -e 64 -e 128 -e 255 -o needle_index
```

#### <a name='Needlequery'></a> Needle query
##### Needle FP analyses
False positive rates are reported by needle during the build step in file [needle_indexIBF_FPRs.fprs](needle_indexIBF_FPRs.fprs). 
On average it is 24.2% (as expected below 25%). However, it can be as high as 64.88%.

These statistics were validated by querying random sequences of size 100, with similar results.

##### Needle FN analyses

We queried 100,000 reads from the first indexed file. Among these queries, 19,274 answers were negative for this file. This is a false negative rate of 19.27%.



### <a name='PebbleScoutcommands'></a> PebbleScout commands
* version v2.25
#### <a name='PebbleScoutbuild'></a> PebbleScout build

```bash
#create the list.txt :
cnt=0
while read file; do
        base_file=$(basename $file .fastq.gz)
    cnt=$((cnt + 1))
        echo  -e "${cnt}\t ${base_file}\t mandatory_metadata"
done < fof.txt > full_list.txt
ln -s full_list.txt list.txt

#create the index
 /usr/bin/time sh run_test_pebblescout_one_tara.sh # cf script directory
#edit the the json files: adjust paths in db.json and db.with_suppressed.json to the directory where you built the database and check that file sizes for *.tr.bin and .vocab are correct in the corresponding json files  under tranTablesSZ and vocabSZ, respectively. Entry for vocabFLDS should reflect metadata fields in the list.txt file.
```

**Note:** killed after 24 hours of computation time, with 32 threads and 350GB of RAM. First set was "harvesed" in approximately 21 hours.

Estimated ETA is 21hx50 = 1050h = 43 days.

#### <a name='PebbleScoutexpectedquery'></a> PebbleScout expected query

Not run as the build was not finished.

```bash
#create the query
zcat head_11SUR1QQSS11.fastq.gz | head -n 2 | tr "@" ">"  > query.fa

#make the search
/usr/bin/time ./pebblescout_v2.25/software/pebblescout/pebblesearch -f query.fa -m 2  -F "QueryID,SubjectID,%coverage,PBSscore,BioSample,Sample,Host" -i  db.json -o score.out 2> score.log
```

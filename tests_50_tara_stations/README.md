This readme file sums up the tested tool versions and the commands used.

A special file kmtricks_dynamicity.md is dedicated to the tests performed comparing the various ways to dynamically update a kmindex index.

<!-- vscode-markdown-toc -->
* 1. [ Data](#Data)
* 2. [ COLD, WARM, and WARM+ queries](#COLDWARMandWARMqueries)
* 3. [ Commands per tool](#Commandspertool)
	* 3.1. [ kmindex commands](#kmindexcommands)
		* 3.1.1. [ kmindex indexing](#kmindexindexing)
		* 3.1.2. [kmindex querying](#kmindexquerying)
	* 3.2. [ MetaGraph commands](#MetaGraphcommands)
		* 3.2.1. [ MetaGraph indexing](#MetaGraphindexing)
	* 3.3. [PAC commands](#PACcommands)
		* 3.3.1. [ PAC Indexing](#PACIndexing)
		* 3.3.2. [ PAC query](#PACquery)
	* 3.4. [ MetaProfi](#MetaProfi)
		* 3.4.1. [ MetaProfi Indexing](#MetaProfiIndexing)
		* 3.4.2. [ MetaProfi query](#MetaProfiquery)
	* 3.5. [ GGCAT commands](#GGCATcommands)
		* 3.5.1. [ GGCAT Indexing](#GGCATIndexing)
		* 3.5.2. [GGCAT Query](#GGCATQuery)
	* 3.6. [ Needle commands](#Needlecommands)
		* 3.6.1. [Needle indexing](#Needleindexing)
		* 3.6.2. [Needle query](#Needlequery)
	* 3.7. [ PebbleScout commands](#PebbleScoutcommands)
		* 3.7.1. [ PebbleScout build](#PebbleScoutbuild)
		* 3.7.2. [ PebbleScout expected query](#PebbleScoutexpectedquery)
* 4. [Computation of false positives](#Computationoffalsepositives)
	* 4.1. [Protocol](#Protocol)
	* 4.2. [FP kmindex](#FPkmindex)
	* 4.3. [FP MetaProfi command](#FPMetaProficommand)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->





##  1. <a name='Data'></a> Data
See the [data](data) directory. 

Moreover except metagraph and kmindex, tested tool do not support file of files. Thus they cannot consider two distinct files as the same data sample. Hence for these tools we had to explicitely concatenate files:

```bash
mkdir data_per_station
cd data_per_station
for station in  `ls ../data_all_clean/QQSS/` ;
do
	echo ${station}
	cat ../data_all_clean/QQSS/${station}/*.fastq.gz > ${station}.fastq.gz 
done	
```

##  2. <a name='COLDWARMandWARMqueries'></a> COLD, WARM, and WARM+ queries

COLD queries are computed after this command, that empty the cache: 
```bash
sync; echo 3 > /proc/sys/vm/drop_caches 
sleep 30
```
WARM queries are computed after a first random query of the same size.

WARM+ queries are computed twice each query.  

##  3. <a name='Commandspertool'></a> Commands per tool

###  3.1. <a name='kmindexcommands'></a> kmindex commands
####  3.1.1. <a name='kmindexindexing'></a> kmindex indexing
See [`fof.txt`](data/fof.txt) file.

```bash
kmindex build -i index_50_tara -f fof.txt -d ./rundir -r index_all_50 -k 23 --cpr --bloom-size  25000000000 --threads 32 --nb-partitions 128
```

####  3.1.2. <a name='kmindexquerying'></a>kmindex querying
```bash
kmindex  query -i index_50_tara -z 5 --threads 32 -o res -q query.fasta
```

###  3.2. <a name='MetaGraphcommands'></a> MetaGraph commands
MetaGraph was used as indicated in this document
https://metagraph.ethz.ch/static/docs/quick_start.html, sections "[Construct canonical graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-canonical-graph)" and "[Construct primary graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-primary-graph)".
####  3.2.1. <a name='MetaGraphindexing'></a> MetaGraph indexing
**Generate the file of file**

```bash 
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create a canonical graph**

```bash
cat fof.txt | metagraph build -p 32 -k 28 --min-count 2 -o index_tara_set_3_QQSS  --disk-swap index_metagraph/temp_disk --mode             canonical --mem-cap-gb 100
```
* Wall clock time: 23h30
* Max RAM: 459GB
* Max Disk: 2634GB
* Size created file (`index_tara_set_3_QQSS.dbg`): 442GB
**Extract a set of primary contigs**

```bash
metagraph transform -v --to-fasta --primary-kmers -o primary_contigs -p 32 index_tara_set_3_QQSS.dbg 
```
* Wall clock time: 22h56
* Max RAM:727GB
* Max Disk: 215GB
* Size created file (`primary_contigs.fasta.gz`): 210GB

**Construct a new graph from the primary contigs and mark this graph as primary**

```bash
metagraph build -v -p 32 -k 28 -o graph_primary --mode primary primary_contigs.fasta.gz
```
* Wall clock time: NA
* Max RAM: >900GB - job killed.
* Max Disk: NA
* Size created file (`graph_primary.dbg`): NA


**Annotate the graph**

Annotation of the graph was not done, as the previous step did not finished. The Annotations would have been done following instructions here: https://github.com/ratschlab/metagraph/issues/412#issuecomment-1181710500, and would have been the following

* Prepare the labeled file of file: 

```bash
python create_fof_from_file_names.py -i fof.txt > fof_annotated.txt
```

`create_fof_from_file_names.py` can be found in the [script](script) directory.

* Annotate the graph:
```bash
while read line; do 
	name=`echo $line | cut -d " " -f 1`; 
	cmd="metagraph annotate -p 32 -i graph_primary.dbg -o ${name} --anno-label ${line}"
	$cmd
done < fof_annotated.txt
```

###  3.3. <a name='PACcommands'></a>PAC commands
Following discussions with the PAC authors, we tested two versions, the one indicated in the original paper, and the version 20b8094f5074e93e792fbf26a5572119c058c23b. 

Here are commands and results obtained with this latest version: 

####  3.3.1. <a name='PACIndexing'></a> PAC Indexing
**Generate the file of file**

```bash 
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create the index**
```bash 
bin/PAC/build/pac -f fof.txt -d Tara_PAC -k 28 -b 30000000000 -e 8 -u -c 32  
```

####  3.3.2. <a name='PACquery'></a> PAC query
```bash
pac -l Tara_PAC -q query.fa -c 32
```

(the output file being empty)


###  3.4. <a name='MetaProfi'></a> MetaProfi
* Tool versions: 
	* python 3.9.5
	* MetaProFi version: v0.6.0
	* K-Mer Counter (KMC) ver. 3.2.2

####  3.4.1. <a name='MetaProfiIndexing'></a> MetaProfi Indexing
We need filtered kmers, so we count kmers using kmc.

##### kmer counting and filtering
```bash
for fq_ile_name in `ls data_per_station/`; do 
	echo ${fq_ile_name}; 
	abs_path=data_per_station/${fq_ile_name}
	canonical_name=`echo ${fq_ile_name} | cut -d "." -f 1`
	./kmc -k28 -m800 -sm -fq -ci2 -cs4 -t32 ${abs_path} ${canonical_name}.res tmp
done


for fq_ile_name in `ls data_per_station/`; do 
	echo ${fq_ile_name}; 
	abs_path=data_per_station/${fq_ile_name}
	canonical_name=`echo ${fq_ile_name} | cut -d "." -f 1`
	./kmc_dump -ci2 ${canonical_name}.res /dev/stdout | awk '{print ">"NR"\n"$1}'| gzip > ${canonical_name}_kmers.fasta.gz
	rm -f ${canonical_name}.res.kmc* 
done
```

##### Build MetaProfi index
Create fof
```bash
for id in `ls counted_kmers/*.fasta`; do canid=`echo $id | cut -d "/" -f 2 | cut -d '_' -f 1`; echo $canid: $id; done > fof.txt
```

Create config file:

```bash
h: 1
k: 28
m: 30000000000
nproc: 32
max_memory: 500GiB
sequence_type: nucleotide
output_directory: index_metaprofi_dir
matrix_store_name: metaprofi_bfmatrix
index_store_name: metaprofi_index
```

Create the index:

```bash
cd /WORKS/expe_MetaProfi
time disk_mem_count.sh  metaprofi build /WORKS/expe_MetaProfi/fof.txt /WORKS/expe_MetaProfi/config_tara.yaml 
```



####  3.4.2. <a name='MetaProfiquery'></a> MetaProfi query
```bash
metaprofi search_index   /WORKS/expe_MetaProfi/config_tara.yaml  -f query.fa -t 10 -i nucleotide
```


###  3.5. <a name='GGCATcommands'></a> GGCAT commands 
**(These results are not included in the kmindex manuscript)**
* Tool versions: ggcat_cmdline 0.1.0

####  3.5.1. <a name='GGCATIndexing'></a> GGCAT Indexing
```bash
ulimit -Hn
500000
ggcat build -c -k 28 --min-multiplicity 2 -j 32 -m 800  -l fof.txt
```

####  3.5.2. <a name='GGCATQuery'></a>GGCAT Query
```bash
ggcat query --colors -k 28 -j 32 --memory 800 --output-file-prefix res output.fasta.lz4 query.fasta 
```
(Killed after 12h computatio time, with query.fa containing a single read)


###  3.6. <a name='Needlecommands'></a> Needle commands 
**(These results are not included in the kmindex manuscript)**
* Tool versions:
    Last update: 
    needle-ibf version: 
    SeqAn version: 3.2.0

####  3.6.1. <a name='Needleindexing'></a>Needle indexing
```bash
ls -dD data_per_station/* > fof.lst
./needle minimiser fof.lst -k 25 -t 32 --cutoff 2  
./needle ibfmin *.minimiser -t 32 -f 0.25 -e 2 -e 255 -o needle_index
```

####  3.6.2. <a name='Needlequery'></a>Needle query
```bash
./needle estimate query.fasta -i needle_index
```
Results are erroneous. This is expected as Needle is based on subsamples of minimizers, and developped for transcripts expressions.


###  3.7. <a name='PebbleScoutcommands'></a> PebbleScout commands
####  3.7.1. <a name='PebbleScoutbuild'></a> PebbleScout build

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
**Note:** killed after 24 hours of computation time, with 32 threads and 350GB of RAM.
 

####  3.7.2. <a name='PebbleScoutexpectedquery'></a> PebbleScout expected query
Not run as the build was not finished.
```bash
#create the query
zcat head_11SUR1QQSS11.fastq.gz | head -n 2 | tr "@" ">"  > query.fa

#make the search
/usr/bin/time ./pebblescout_v2.25/software/pebblescout/pebblesearch -f query.fa -m 2  -F "QueryID,SubjectID,%coverage,PBSscore,BioSample,Sample,Host" -i  db.json -o score.out 2> score.log
```

##  4. <a name='Computationoffalsepositives'></a>Computation of false positives
The false positive rates were computed on the only tools for which we could compute perform queries: MetaProfi, and kmindex. We remind that PAC provided an empty output file, and that other tools either did not finish the indexing, or did not finish a single query.

###  4.1. <a name='Protocol'></a>Protocol
We gerated a random sequence composed of 10k nucleotides with an equal probability of each nucloetide. This sequence is in the `data` directory of this repository.

We queried the $10000-28+1$ 28-mers of this sequence, and counted the number of positive answers. We abusively call this number the number of false positives. Notice that this is an over estimation of the number of false positives, as some of the 28-mers of the random sequence may be present in the reference dataset, with a tiny probability of $1/4^{28}$.

###  4.2. <a name='FPkmindex'></a>FP kmindex
**Note**: the `data/test_FP` directory contains the [random sequence](data/test_FP/random_10k.fa) and results files ([FPkmindex.txt](data/test_FP/FPkmindex.txt) and [metaprofi_query_results-11_10_2023-10_34_28_t0](data/test_FP/metaprofi_query_results-11_10_2023-10_34_28_t0.txt)) of tested tools. 

**Query** 
```bash
kmindex query -i TaraIndex -q random_10k.fa -z 5 -o res_random_10k;
```

**Analyses**
```bash
cat res_random_10k/QQSS.json | grep QQSS11 | cut -d ":" -f 2 | cut -d ',' -f 1 > FPkmindex.txt

cat FPkmindex.txt | sort -n | awk '
  BEGIN {
    c = 0;
    sum = 0;
	nb_nul = 0
  }
  $1 ~ /^(\-)?[0-9]*(\.[0-9]*)?$/ {
    a[c++] = $1 * 100;
    sum += $1 * 100;
		if( $1 == 0 ) {
			nb_nul = nb_nul + 1;
		}
  }
  END {
    ave = sum / c;
    if( (c % 2) == 1 ) {
      median = a[ int(c/2) ];
    } else {
      median = ( a[c/2] + a[c/2-1] ) / 2;
    }
    OFS="\t";
    print sum, c, ave, median, a[0], a[c-1], nb_nul;
  }
'
```
Result: 
| sum | size | avg | median | min | max | nb_nul |
| --- | --- | --- | --- | --- | --- | --- |
| 0.4813 |	50	|0.00962599	|0|	0|	0.180487 |35|

###  4.3. <a name='FPMetaProficommand'></a>FP MetaProfi command
```bash
metaprofi search_index config_tara.yaml  -f random_10k.fa -t 0 -i nucleotide
```

**Analyses**
```bash
cat index_metaprofi_dir/metaprofi_query_results-11_10_2023-10_34_28_t0.txt | grep \% | cut -d "(" -f 2 | cut -d "%" -f 1 | sort -n | awk '
  BEGIN {
    c = 0;
    sum = 0;
    nb_nul = 0
  }
  $1 {
    a[c++] = $1 
    sum += $1 
		if( $1 == 0 ) {
			nb_nul = nb_nul + 1;
		}
  }
  END {
    ave = sum / c;
    if( (c % 2) == 1 ) {
      median = a[ int(c/2) ];
    } else {
      median = ( a[c/2] + a[c/2-1] ) / 2;
    }
    OFS="\t";
    print sum, c, ave, median, a[0], a[c-1], nb_nul;
  }
  '
```
Result:
| sum | size | avg | median | min | max | nb_nul |
| --- | --- | --- | --- | --- | --- | --- |
| 558.9 | 50 | 11.178 | 10.445 | 6.93 | 21.55 | 0 |


<!-- vscode-markdown-toc -->
* 1. [kmindex indexing](#kmindexindexing)
* 2. [kmindex querying](#kmindexquerying)
* 3. [MetaGraph indexing](#MetaGraphindexing)
* 4. [PAC Indexing](#PACIndexing)
* 5. [PAC query](#PACquery)
* 6. [MetaProfi Indexing](#MetaProfiIndexing)
	* 6.1. [kmer counting and filtering](#kmercountingandfiltering)
	* 6.2. [Build MetaProfi index](#BuildMetaProfiindex)
	* 6.3. [MetaProfi query](#MetaProfiquery)
* 7. [GGCAT commands (These results are not included in the kmindex manuscript)](#GGCATcommandsTheseresultsarenotincludedinthekmindexmanuscript)
	* 7.1. [GGCAT Indexing](#GGCATIndexing)
	* 7.2. [GGCAT QUERY](#GGCATQUERY)
* 8. [Needle commands (These results are not included in the kmindex manuscript)](#NeedlecommandsTheseresultsarenotincludedinthekmindexmanuscript)
	* 8.1. [Needle indexing](#Needleindexing)
	* 8.2. [Needle query](#Needlequery)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

# Data
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

# COLD and WARM queries
WARM queries are computed twice each query.
COLD queries are computed after this command, that empty the cache: 

```bash
sudo systemctl start drop_cache.service
sleep 30
```

# kmindex commands 
##  1. <a name='kmindexindexing'></a>kmindex indexing
See `data/fof.txt` file

```bash
K=23
M=2
T=32
P=128
B=25000000000
kmindex build -i index_50_tara -f fof.txt -d ./rundir -r index_all_50 -k ${K} --cpr --bloom-size ${B}  --threads ${T} --nb-partitions ${P}
```

##  2. <a name='kmindexquerying'></a>kmindex querying
```bash
Z=3
T=32
kmindex  query -i index_50_tara -z ${Z} --threads ${T} -o res -q query.fasta
```

# MetaGraph commands
MetaGraph was used as indicated in this document
https://metagraph.ethz.ch/static/docs/quick_start.html, sections "[Construct canonical graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-canonical-graph)" and "[Construct primary graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-primary-graph)".
##  3. <a name='MetaGraphindexing'></a>MetaGraph indexing
**Generate the file of file**

```bash 
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create a canonical graph**

```bash
cat fof.txt | metagraph build -p 32 -k 23 --min-count 2 -o index_tara_set_3_QQSS  --disk-swap index_metagraph/temp_disk --mode             canonical --mem-cap-gb 100
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
metagraph build -v -p 32 -k 23 -o graph_primary --mode primary primary_contigs.fasta.gz
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

# PAC commands
Following discussions with the PAC authors, we tested two versions, the one indicated in the original paper, and the version 20b8094f5074e93e792fbf26a5572119c058c23b. 

Here are commands and results obtained with this latest version: 

##  4. <a name='PACIndexing'></a>PAC Indexing
**Generate the file of file**

```bash 
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create the index**
```bash 
bin/PAC/build/pac -f fof.txt -d Tara_PAC -k 28 -b 30000000000 -e 8 -u -c 32  
```

##  5. <a name='PACquery'></a>PAC query
```bash
pac -l Tara_PAC -q query.fa -c 32
```

(the output file being empty)


# MetaProfi
* Tool versions: 
	* python 3.9.5
	* MetaProFi version: v0.6.0
	* K-Mer Counter (KMC) ver. 3.2.2

##  6. <a name='MetaProfiIndexing'></a>MetaProfi Indexing
We need filtered kmers, so we count kmers using kmc.

###  6.1. <a name='kmercountingandfiltering'></a>kmer counting and filtering
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

###  6.2. <a name='BuildMetaProfiindex'></a>Build MetaProfi index
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



###  6.3. <a name='MetaProfiquery'></a>MetaProfi query
```bash
metaprofi search_index   /WORKS/expe_MetaProfi/config_tara.yaml  -f query.fa -t 10 -i nucleotide
```


##  7. <a name='GGCATcommandsTheseresultsarenotincludedinthekmindexmanuscript'></a>GGCAT commands (These results are not included in the kmindex manuscript)
* Tool versions: ggcat_cmdline 0.1.0

###  7.1. <a name='GGCATIndexing'></a>GGCAT Indexing
```bash
ulimit -Hn
500000
ggcat build -c -k 28 --min-multiplicity 2 -j 32 -m 800  -l fof.txt
```

###  7.2. <a name='GGCATQUERY'></a>GGCAT QUERY
```bash
ggcat query --colors -k 28 -j 32 --memory 800 --output-file-prefix res output.fasta.lz4 query.fasta 
```
(Killed after 12h computatio time, with query.fa containing a single read)


##  8. <a name='NeedlecommandsTheseresultsarenotincludedinthekmindexmanuscript'></a>Needle commands (These results are not included in the kmindex manuscript)
* Tool versions:
    Last update: 
    needle-ibf version: 
    SeqAn version: 3.2.0

###  8.1. <a name='Needleindexing'></a>Needle indexing
```bash
ls -dD data_per_station/* > fof.lst
./needle minimiser fof.lst -k 25 -t 32 --cutoff 2  
./needle ibfmin *.minimiser -t 32 -f 0.25 -e 2 -e 255 -o needle_index
```

###  8.2. <a name='Needlequery'></a>Needle query
```bash
./needle estimate query.fasta -i needle_index
```
Results are erroneous. This is expected as Needle is based on subsamples of minimizers, and developped for transcripts expressions.



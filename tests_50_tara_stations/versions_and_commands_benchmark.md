This note sums up the tested tool versions and the commands used to build indexes and perform queries on the 50 TARA stations dataset.

<!-- vscode-markdown-toc -->
* [Data](#Data)
* [ COLD, WARM, and WARM+ queries](#COLDWARMandWARMqueries)
* [ Commands per tool](#Commandspertool)
	* [ kmindex](#kmindex)
		* [ kmindex indexing](#kmindexindexing)
		* [kmindex querying](#kmindexquerying)
	* [ MetaGraph](#MetaGraph)
		* [ MetaGraph indexing](#MetaGraphindexing)
	* [PAC](#PAC)
		* [ PAC Indexing](#PACIndexing)
		* [ PAC query](#PACquery)
	* [ MetaProfi](#MetaProfi)
		* [ MetaProfi Indexing](#MetaProfiIndexing)
		* [ MetaProfi query](#MetaProfiquery)
	* [ GGCAT commands](#GGCATcommands)
		* [ GGCAT Indexing](#GGCATIndexing)
		* [GGCAT Query](#GGCATQuery)
	* [Themisto](#Themisto)
	* [HFBI](#HFBI)
	* [Bifrost](#Bifrost)

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


## <a name='Data'></a>Data

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

## <a name='COLDWARMandWARMqueries'></a> COLD, WARM, and WARM+ queries

COLD queries are computed after this command, that empty the cache: 

```bash
sync; echo 3 > /proc/sys/vm/drop_caches 
sleep 30
```

WARM queries are computed after a first random query of the same size.

WARM+ queries are computed twice each query.  

## <a name='Commandspertool'></a> Commands per tool

### <a name='kmindex'></a> kmindex
* Version v0.5.2
#### <a name='kmindexindexing'></a> kmindex indexing

See [`fof.txt`](data/fof.txt) file.

```bash
kmindex build -i index_50_tara -f fof.txt -d ./rundir -r index_all_50 -k 23 --cpr --bloom-size  25000000000 --threads 32 --nb-partitions 128
```

#### <a name='kmindexquerying'></a>kmindex querying

```bash
kmindex  query -i index_50_tara -z 5 --threads 32 -o res -q query.fasta
```

### <a name='MetaGraph'></a> MetaGraph
* version v0.3.6
* MetaGraph was used as indicated in this document
https://metagraph.ethz.ch/static/docs/quick_start.html, sections "[Construct canonical graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-canonical-graph)" and "[Construct primary graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-primary-graph)".

#### <a name='MetaGraphindexing'></a> MetaGraph indexing

**Generate the file of file**

```bash
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

1. Construct sample graphs first, then extract primary contigs from them and use these contigs to construct a joint graph.

```bash
ls -d /WORKS/expes_indexations/data_50_tara/data_per_station/*fastq.gz > fof.txt 
while read file; do
		bfile=$(basename -s .fastq.gz $file)
    mkdir ${bfile}.kmc_cache;
    ./kmc -k28 -m6 -sm -ci2 -fq -t32 $file ${bfile}.kmc ${bfile}.kmc_cache;
    metagraph build -p 32 -k 28 --mode canonical -o ${bfile} ${bfile}.kmc.kmc_suf --disk-swap temp_disk --mem-cap-gb 100;
    metagraph transform -v --to-fasta --primary-kmers -o ${bfile}.contigs -p 32 ${bfile}.dbg;
    rm -r ${bfile}.kmc_cache ${bfile}.dbg ${bfile}.kmc*;
done < fof.txt
```
(Took 12h47, RAM not logged, disk space used: 90GB)

2. Construct a joint graph from the contigs extracted from the sample graphs
```bash
ls *.contigs.fasta.gz > contigs.txt
cat contigs.txt | metagraph build -p 32 -k 28 -o index_tara_set_3_QQSS --mode canonical --disk-swap temp_disk --mem-cap-gb 100
metagraph transform -v --to-fasta --primary-kmers -o primary_contigs -p 32 index_tara_set_3_QQSS.dbg
metagraph build -v -p 32 -k 28 -o graph_primary --mode primary primary_contigs.fasta.gz --disk-swap temp_disk --mem-cap-gb 100
```
(Took 16:57, max 201GB RAM, max disk space used: 1585GB)

3. Annotate the graph
```bash
mkdir columns
cat contigs.txt | metagraph annotate -v -i graph_primary.dbg --anno-filename --separately -o columns -p 4 --threads-each 8
```
(Took 6:52, max 243GB RAM, max disk space used: 179GB)

4. Transform to a final representation:
Finally, graph columns are an intermediate annotation representation. Querying them sequentially is extremely inefficient.
The correct way would be to transform them to a final representation, which is more compressed AND faster to query. By default, we use row_diff_brwt or row_diff_sparse.

```bash

mkdir -p rd/rd_columns
cd rd/
ln -s ../graph_primary.dbg ./graph.dbg
cd -

echo "transform_anno 1"
find columns -name "*.annodbg"  | metagraph transform_anno -v --anno-type row_diff --row-diff-stage 0 --mem-cap-gb 500 --disk-swap temp_disk -i rd/graph.dbg -o rd/rd_columns/out -p 32
echo "transform_anno 2"
find columns -name "*.annodbg"  | metagraph transform_anno -v --anno-type row_diff --row-diff-stage 1 --mem-cap-gb 500 --disk-swap temp_disk -i rd/graph.dbg -o rd/rd_columns/out -p 32
echo "transform_anno 3"
find columns -name "*.annodbg"  | metagraph transform_anno -v --anno-type row_diff --row-diff-stage 2 --mem-cap-gb 500 --disk-swap temp_disk -i rd/graph.dbg -o rd/rd_columns/out -p 32

echo "transform_anno end"
find rd/rd_columns -name "*.annodbg" | metagraph transform_anno -v --anno-type row_diff_sparse -i rd/graph.dbg -o annotation -p 32
```
(Killed after 14h17, with 900GB of RAM used, max disk used 2144GB)

**Summup:** Killed after 50h53, with 900GB of RAM used, max disk used 2144GB

### <a name='PAC'></a>PAC

* Following discussions with the PAC authors, we tested two versions, the one indicated in the original paper, and the version 20b8094f5074e93e792fbf26a5572119c058c23b. 

Here are commands and results obtained with this latest version: 

#### <a name='PACIndexing'></a> PAC Indexing

**Generate the file of file**

```bash
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create the index**

```bash
bin/PAC/build/pac -f fof.txt -d Tara_PAC -k 28 -b 30000000000 -e 8 -u -c 32  
```

#### <a name='PACquery'></a> PAC query

```bash
pac -l Tara_PAC -q query.fa -c 32
```

(the output file being empty)

### <a name='MetaProfi'></a> MetaProfi

* Tool versions: 
  * python 3.9.5
  * MetaProFi version: v0.6.0
  * K-Mer Counter (KMC) ver. 3.2.2

#### <a name='MetaProfiIndexing'></a> MetaProfi Indexing

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

#### <a name='MetaProfiquery'></a> MetaProfi query

```bash
metaprofi search_index   /WORKS/expe_MetaProfi/config_tara.yaml  -f query.fa -t 10 -i nucleotide
```

### <a name='GGCATcommands'></a> GGCAT commands

**(These results are not included in the kmindex manuscript)**

* Tool versions: ggcat_cmdline 0.1.0

#### <a name='GGCATIndexing'></a> GGCAT Indexing

```bash
ulimit -Hn
500000
ggcat build -c -k 28 --min-multiplicity 2 -j 32 -m 800  -l fof.txt
```

#### <a name='GGCATQuery'></a>GGCAT Query

```bash
ggcat query --colors -k 28 -j 32 --memory 800 --output-file-prefix res output.fasta.lz4 query.fasta 
```

(Killed after 12h computatio time, with query.fa containing a single read)


### <a name='Themisto'></a>Themisto
* Version linux_v3.2.0
```bash
./themisto_linux_v3.2.0/themisto  build -k 28 -i fof.txt --index-prefix tara50 --temp-dir temp --mem-gigas 800 --n-threads 32 --file-colors 
```

Was killed after 9h14, reaching the machine limit of 900GB of RAM, and using 4.7TB of disk space.


### <a name='HFBI'></a>HFBI
* Versions:
	* Raptor version: 3.0.0 (commit unavailable)
  * Sharg version: 1.0.1-rc.1
  * SeqAn version: 3.3.0-rc.1

```bash
raptor prepare --input fof.txt --output out_raptor --threads 32 --kmer 28 --kmer-count-cutoff 2

16:53.10 real,  6724.50 user,   253.93 sys,     0 amem, 943714776 mmem
```
Ran out of RAM after ~17h, with 900GB of RAM used.


### <a name='Bifrost'></a>Bifrost
* Version: 1.3.0

```bash
./Bifrost build -t 32 -k 28 -s fof.txt -o 50_graph
``` 
Ran out of RAM after ~13h, with 900GB of RAM used.




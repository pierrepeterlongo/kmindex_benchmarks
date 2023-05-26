# Data
See the [data](data) directory. 


# kmindex commands 
## Indexing
See `data/fof.txt` file

```bash
K=23
M=2
T=32
P=128
B=25000000000
kmindex build -i index_50_tara -f fof.txt -d ./rundir -r index_all_50 -k ${K} --cpr --bloom-size ${B}  --threads ${T} --nb-partitions ${P}
```

## Querying
```bash
Z=3
T=32
kmindex  query -i index_50_tara -z ${Z} --threads ${T} -o res -q query.fasta
```

# MetaGraph commands
MetaGraph was used as indicated in this document
https://metagraph.ethz.ch/static/docs/quick_start.html, sections "[Construct canonical graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-canonical-graph)" and "[Construct primary graph](https://metagraph.ethz.ch/static/docs/quick_start.html#construct-primary-graph)".
## Indexing
**Generate the file of file**

```bash 
ls /path/to/read/files/*.fastq.gz > fof.txt 
```

**Create a canonical graph**

```bash
cat fof.txt | metagraph build -p 32 -k 23 --min-count 2 -o index_tara_set_3_QQSS  --disk-swap /WORKS/expe_kmindex/index_metagraph/temp_disk --mode             canonical --mem-cap-gb 100
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
* Wall clock time: 
* Max RAM:
* Max Disk: 
* Size created file (`XXX`): 




<!-- vscode-markdown-toc -->
* 1. [Data](#data). 
* 2. [Test avec registering](#testavecregistering). 
	* 2.1. [Indexing](#indexing). 
	* 2.2. [Query](#query). 
* 3. [Test avec merging](#testavecmerging). 
	* 3.1. [Indexing](#indexing-1). 
	* 3.2. [Querying](#querying). 
* 4. [Orignal index of the 50 samples:](#orignalindexofthe50samples:). 
	* 4.1. [Indexing](#indexing-1). 
	* 4.2. [Querying](#querying-1). 

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->* Tool versions: kmindex 0.4.0


##  1. <a name='data'></a>Data
```bash
head -n 10 fof.txt > fof1.txt
head -n 20 fof.txt | tail -n 10 > fof2.txt
head -n 30 fof.txt | tail -n 10 > fof3.txt
head -n 40 fof.txt | tail -n 10 > fof4.txt
head -n 50 fof.txt | tail -n 10 > fof5.txt
```

##  2. <a name='testavecregistering'></a>Test avec registering

###  2.1. <a name='indexing'></a>Indexing
```bash
cd ##registering

K=23
M=2
T=32
P=128
B=25000000000

fofid=1
kmindex build -i index_50_tara -f ../data/fof${fofid}.txt -d ./rundir_${fofid} -r fof${fofid} --km-path ../bin/kmtricks -k ${K} --cpr --bloom-size ${B}  --threads ${T} --nb-partitions ${P}

for fofid in 2 3 4 5
do
    kmindex build -i index_50_tara -f ../data/fof${fofid}.txt -d ./rundir_${fofid} -r fof${fofid} --km-path ../bin/kmtricks --cpr  --threads ${T} --from fof1 --bloom-size 12  --nb-partitions ${P}
done
```
Note: in theory we don't need (fake) --bloom-size 12 or --nb-partitions ${P} - it's a display bug that will be solved in next release

###  2.2. <a name='query'></a>Query
```bash
T=32
Z=5

for size in 1 10 100 1000 10000 100000 1000000 10000000; 

do
    # clear cache
    sudo systemctl start drop_cache.service
    sleep 30
    kmindex  query -i index_50_tara_register -z ${Z} --threads ${T} -o res_${size} -q ${size}.fasta --fast -s all
    
done
```


##  3. <a name='testavecmerging'></a>Test avec merging
###  3.1. <a name='indexing-1'></a>Indexing
(we don't redo the index, we start from what was created previously)
```bash
cd merging

for fofid in 1 2 3 4 5
do
    kmindex register -i index_50_tara_register/ -n fof${fofid} -p registering/rundir_${fofid}
done

kmindex merge -i index_50_tara_register -n Merged -p ./merged_index -m fof1,fof2,fof3,fof4,fof5 
```

###  3.2. <a name='querying'></a>Querying
```bash
cd merging
T=32
Z=5
for size in 1 10 100 1000 10000 100000 1000000 10000000; 
do
    # clear cache
    sudo systemctl start drop_cache.service
    sleep 30
    kmindex  query -i index_50_tara_register -z ${Z} --threads ${T} -o res_${size} -q ${size}.fasta --fast -s all
done
```

##  4. <a name='orignalindexofthe50samples:'></a>Orignal index of the 50 samples:
###  4.1. <a name='indexing-1'></a>Indexing
```bash
cd original
K=23
M=2
T=32
P=128
B=25000000000
kmindex build -i index_50_tara -f ../data/fof.txt -d ./rundir -r fof_all --km-path ../bin/kmtricks -k ${K} --cpr --bloom-size ${B}  --threads ${T} --nb-partitions ${P}
```

###  4.2. <a name='querying-1'></a>Querying 
```bash
cd original
T=32
Z=5
for size in 1 10 100 1000 10000 100000 1000000 10000000; 
do
    # clear cache
    sudo systemctl start drop_cache.service
    sleep 30
    kmindex  query -i index_50_tara -z ${Z} --threads ${T} -o res_${size} -q ${size}.fasta --fast  -s all
done
```

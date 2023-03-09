# Command used for estimation of kmer cardinality 
* Command estimating the cardinality of kmers for each input read set

```bash
ntcard -k23 -o out.ntcard read_files_file_of_file.txt
```



* Number of distinct kmers per dataset

```bash
for file in *.ntcard
do
echo -n $file" " && tail -n 1000 ${file} | cut -f 3 | paste -sd+ - | bc
done
```



* Number of distinct kmers occurring at least twice per dataset

```bash
for file in *.ntcard
do
echo -n $file" " && tail -n 999 ${file} | cut -f 3 | paste -sd+ - | bc
done
```


This note describes the computation of false negatives rates of the tested tools which were able to build an index and perform queries on the 50 TARA stations dataset: kmindex and MetaProfi.


The false positive rates were computed on the only tools for which we could compute perform queries: MetaProfi, and kmindex. We remind that PAC provided an empty output file, and that other tools either did not finish the indexing, or did not finish a single query.



<!-- vscode-markdown-toc -->
* [Protocol](#protocol). 
* [Theoretical analyse](#theoreticalanalyse). . 
* [Results kmindex](#resultskmindex). 
* [Results MetaProfi](#resultsmetaprofi). 

<!-- vscode-markdown-toc-config
	numbering=false
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## <a name='protocol'></a>Protocol

We gerated a random sequence composed of 10k nucleotides with an equal probability of each nucloetide. This sequence is in the `data` directory of this repository.

We queried the $10000-28+1$ 28-mers of this sequence, and counted the number of positive answers. We abusively call this number the number of false positives. Notice that this is an over estimation of the number of false positives, as some of the 28-mers of the random sequence may be present in the reference dataset, with a tiny probability of $1/4^{28}$.


**Note**: the `data/test_FP` directory contains the [random sequence](data/test_FP/random_10k.fa) and results files ([FPkmindex.txt](data/test_FP/FPkmindex.txt) and [metaprofi_query_results-11_10_2023-10_34_28_t0](data/test_FP/metaprofi_query_results-11_10_2023-10_34_28_t0.txt)) of tested tools.

## <a name='theoreticalanalyse'></a>Theoretical analyse
We provide the theoretical expected false positive rates. This is computed by counting the number of distinct kmers indexed in each of the 50 read sets:

```bash
> python stat_spectrums.py
Average Sum: 3708576010
Median Sum: 3419461766
Minimum Sum: 2132572901
Maximum Sum: 7167771868
```

Note that [stat_spectrums.py](script/stat_spectrums.py)  is provided in the script directory.


We considere the best case scenario, offered by metaprofi in which the bloom filter size is 30 billions bits (kmindex uses only 25 billions).

We thus computed for the average, median, min and max number of distinct kmers, the expected number of false positives, using the following formula: $1 - exp(-\frac{n}{m})$ where $m$ is the size of the BF (30 billions) and $n$ is the number of distinct kmers.


**Theoretical results:** 


Result:
| size | avg | median | min | max | nb_nul |
| --- | --- | --- | --- | --- | --- |
| 50 | 11.63 | 10.77 | 6.86 | 21.25 | 0 |


## <a name='resultskmindex'></a>Results kmindex 

 

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
| 0.4813 |    50    |0.00962599    |0|    0|    0.180487 |35|

## <a name='resultsmetaprofi'></a>Results MetaProfi


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


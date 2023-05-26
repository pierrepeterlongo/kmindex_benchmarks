#! /usr/bin/env bash

function usage ()
{
  echo "kmindex bench script "
  echo "Usage: "
  echo "  ./prepare_queries.sh [-p STR] [-w STR] [-i INT] [-n INT ] [-q STR] [-t INT]"
  echo "Options: "
  echo "  -p <STR>        -> Fasta pool."
  echo "  -o <STR>        -> Output directory."
  echo "  -h              -> show help."
  exit 1
}

pool_path=""
seed=123456789
seed2=987654321
out_dir=""

size_array= ( 1 10 100 1000 10000 100000 1000000 10000000 )

while getopts "p:o:" option; do
  case "$option" in
    p)
      pool_path=${OPTARG}
      ;;
    o)
      out_dir=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

mkdir ${out_dir}

for i in "${size_array[@]}"; do
  seqkit sample -p 0.8 -s ${seed} ${pool_path} | seqkit head -n ${i} > ${out_dir}/${i}.fasta
  seqkit sample -p 0.8 -s ${seed2} ${pool_path} | seqkit head -n ${i} > ${out_dir}/${i}_warmup.fasta
done



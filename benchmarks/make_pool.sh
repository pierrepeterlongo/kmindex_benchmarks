#! /usr/bin/env bash

function usage ()
{
  echo "kmindex bench script "
  echo "Usage: "
  echo "  ./make_pool.sh [-f STR] [-o STR]"
  echo "Options: "
  echo "  -p <STR>        -> Fof."
  echo "  -o <STR>        -> Output file."
  echo "  -h              -> show help."
  exit 1
}

fof_path=""
out_file=""
seed=123456789

while getopts "f:o:" option; do
  case "$option" in
    f)
      fof_path=${OPTARG}
      ;;
    o)
      out_file=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done


while IFS= read -r line; do
  seqkit sample -p 0.5 -s ${seed} ${line} | seqkit fq2fa | seqkit head -n 1000000 >> ${out_file}_tmp
done < ${fof_path}

seqkit shuffle -s ${seed} -2 ${out_file}_tmp > ${out_file}

rm -rf ${out_file}_tmp ${out_file}_tmp.seqkit.fai




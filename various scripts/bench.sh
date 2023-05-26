#! /usr/bin/env bash

function usage ()
{
  echo "kmindex bench script "
  echo "Usage: "
  echo "  ./kmindex_bench.sh [-p STR] [-w STR] [-i INT] [-n INT ] [-q STR] [-t INT]"
  echo "Options: "
  echo "  -p <STR>        -> Path to executble."
  echo "  -w <STR>        -> Warmup file"
  echo "  -i <STR>        -> Index path"
  echo "  -n <INT>        -> Number of queries."
  echo "  -q <STR>        -> Query file."
  echo "  -t <INT>        -> Number of threads."
  echo "  -h              -> show help."
  exit 1
}

kmindex_path=""
warmup_file=""
index_path=""
nb_queries=0
query_file=""
nb_threads=""

while getopts "p:w:i:n:q:t:" option; do
  case "$option" in
    p)
      kmindex_path=${OPTARG}
      ;;
    w)
      warmup_file=${OPTARG}
      ;;
    i)
      index_path=${OPTARG}
      ;;
    n)
      nb_queries=${OPTARG}
      ;;
    q)
      query_file=${OPTARG}
      ;;
    t)
      nb_threads=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

batch_size=$(expr ${nb_queries} / ${nb_threads})

function run_kmindex ()
{
  kmindex query -i ${1} -q ${2} --batch-size ${3} -t ${4} -f matrix > /dev/null 2>&1
}

function run_kmindex_report ()
{
  /usr/bin/time -f %E,%M sh -c "kmindex query -i ${1} -q ${2} --batch-size ${3} -t ${4} -f matrix > /dev/null 2>&1"
}

# On our node, we have a service for dropping pagecache, inodes and dentries.
# The same behavior can be achieved using 'echo 3 | sudo tee /proc/sys/vm/drop_caches'
sudo systemctl start drop_cache.service

[[ ! -z "${warmup_file}" ]] && run_kmindex ${index_path} ${query_file} ${batch_size} ${nb_threads}

run_kmindex_report ${index_path} ${query_file} ${batch_size} ${nb_threads}


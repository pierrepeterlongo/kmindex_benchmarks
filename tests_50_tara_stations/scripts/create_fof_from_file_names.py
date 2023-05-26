#! /usr/bin/env python3
import argparse

# FROM
""" 
/7SUR1QQSS11/AHX_AAGOSU_6_1_814P9ABXX_clean.fastq.gz
/7SUR1QQSS11/AHX_AAGOSU_6_2_814P9ABXX_clean.fastq.gz
/80SUR1QQSS11/AHX_CGIIOSF_4_1_D2GCPACXX.IND17_clean.fastq.gz
/80SUR1QQSS11/AHX_CGIIOSF_4_2_D2GCPACXX.IND17_clean.fastq.gz
/81SUR1QQSS11/AHX_BPQIOSF_5_1_D2GD8ACXX.IND8_clean.fastq.gz
/81SUR1QQSS11/AHX_BPQIOSF_5_2_D2GD8ACXX.IND8_clean.fastq.gz
/82SUR0QQSS11/AHX_ATLIOSF_6_1_D0Y2MACXX.IND6_clean.fastq.gz
/82SUR0QQSS11/AHX_ATLIOSF_6_2_D0Y2MACXX.IND6_clean.fastq.gz
""" 

# TO
"""
7SUR1QQSS11 /7SUR1QQSS11/AHX_AAGOSU_6_1_814P9ABXX_clean.fastq.gz /7SUR1QQSS11/AHX_AAGOSU_6_2_814P9ABXX_clean.fastq.gz
80SUR1QQSS11 /80SUR1QQSS11/AHX_CGIIOSF_4_1_D2GCPACXX.IND17_clean.fastq.gz /80SUR1QQSS11/AHX_CGIIOSF_4_2_D2GCPACXX.IND17_clean.fastq.gz
81SUR1QQSS11 /81SUR1QQSS11/AHX_BPQIOSF_5_1_D2GD8ACXX.IND8_clean.fastq.gz /81SUR1QQSS11/AHX_BPQIOSF_5_2_D2GD8ACXX.IND8_clean.fastq.gz
... (Not alway 2 files per station)
"""

def main():
    parser = argparse.ArgumentParser(description="Transform a list of file names into a fof file")
    parser.add_argument("-i", help="name of a file for instance",
                        dest='in_file', type=str, required=True)
    args = parser.parse_args()

    prev_name = ""
    with open(args.in_file, 'r') as f:
        for line in f:
            line = line.strip()
            name = line.split("/")[-2]
            if name != prev_name:
                if prev_name != "":
                    print() # new line
                print(name, end="")
            print(" "+line, end="")
            prev_name = name
    
    
if __name__ == "__main__":
    main ()
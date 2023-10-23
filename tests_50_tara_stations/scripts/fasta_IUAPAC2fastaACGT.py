import random
import sys

def random_nucleotide():
    return random.choice("ACGT")

def replace_non_acgt(char):
    if char not in "ACGT":
        return random_nucleotide()
    return char

def process_fasta(input_filename, output_filename):
    with open(input_filename, "r") as input_file, open(output_filename, "w") as output_file:
        current_sequence = None

        for line in input_file:
            line = line.strip()

            if line.startswith(">"):
                # This line contains the sequence identifier
                if current_sequence is not None:
                    output_file.write(current_sequence + "\n")
                output_file.write(line + "\n")
                current_sequence = ""
            else:
                # This line contains sequence data
                current_sequence += "".join(replace_non_acgt(char) for char in line)

        if current_sequence is not None:
            output_file.write(current_sequence + "\n")

def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py input_filename output_filename")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    process_fasta(input_filename, output_filename)

if __name__ == "__main__":
    main()

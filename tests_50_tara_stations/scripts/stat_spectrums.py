import glob
import statistics

# Specify the directory where your "*.ntcard" files are located
directory = "../data/kmer_spectrums/"

# Create an empty list to store the sum of "n" values from each file
sums = []

# Use glob to find all "*.ntcard" files in the specified directory
ntcard_files = glob.glob(directory + "*.ntcard")

# Iterate through each file
for file_path in ntcard_files:
    with open(file_path, 'r') as file:
        lines = file.readlines()[2:]  # Skip the header line and th first line containing kmers occurring once, filtered out at indexing time
        sum_n = sum(int(line.split('\t')[2]) for line in lines)
        sums.append(sum_n) 

# Calculate statistics
average_sum = int(sum(sums) / len(sums))
median_sum = int(statistics.median(sums))
min_sum = min(sums)
max_sum = max(sums)

# Print the results
print(f"Average Sum: {average_sum}")
print(f"Median Sum: {median_sum}")
print(f"Minimum Sum: {min_sum}")
print(f"Maximum Sum: {max_sum}")

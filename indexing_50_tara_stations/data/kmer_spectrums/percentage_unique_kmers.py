import os

# Get the current directory
current_dir = os.getcwd()

# Initialize variables
total_n = 0

# Loop through all files in the directory
for filename in os.listdir(current_dir):
    # Check if the file ends with .ntcard
    if filename.endswith(".ntcard"):
        # Open the file
        with open(filename, "r") as f:
            # Skip the first line
            next(f)
            # Read the rest of the file and sum up all n values
            for line in f:
                parts = line.strip().split("\t")
                total_n += int(parts[2])

total_first_n = 0
for filename in os.listdir(current_dir):
    # Check if the file ends with .ntcard
    if filename.endswith(".ntcard"):
        # Open the file
        with open(filename, "r") as f:
            # Skip the first line
            next(f)
            # Read the first line and extract the n value
            for line in f:
                total_first_n += int(line.strip().split("\t")[2])
                break

# Calculate the ratio of the sum of all n values to the sum of the first n values
ratio = total_first_n / total_n
print(f"Ratio: {ratio} ({total_first_n} / {total_n} kmers are unique)")

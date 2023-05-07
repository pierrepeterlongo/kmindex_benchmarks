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
                total_n += int(parts[2]) * int(parts[1])

# prints the total number of kmers
print(total_n)

import numpy as np
import random
import os

# Define the folder path where test cases will be saved
folder_path = "testcases"

# Create the folder if it doesn't exist
os.makedirs(folder_path, exist_ok=True)

def generate_testcase(filename):
    # Randomly select values for N, M, padding, and stride within constraints
    N = float(random.randint(3, 7))       # Size of the image matrix (3 ≤ N ≤ 7)
    M = float(random.randint(2, 4))       # Size of the kernel matrix (2 ≤ M ≤ 4)
    padding = float(random.randint(0, 4)) # Padding value (0 ≤ p ≤ 4)
    stride = float(random.randint(1, 3))  # Stride value (1 ≤ s ≤ 3)

    # Generate random floating-point numbers for the image and kernel matrices
    image_matrix = np.round(np.random.uniform(-10, 10, (int(N), int(N))), 1)
    kernel_matrix = np.round(np.random.uniform(-10, 10, (int(M), int(M))), 1)

    # Write to the file
    with open(filename, 'w') as f:
        # First line: N, M, padding, and stride with one decimal place
        f.write(f"{N:.1f} {M:.1f} {padding:.1f} {stride:.1f}\n")
        
        # Second line: Flattened image matrix with one decimal place
        image_flat = ' '.join(f"{num:.1f}" for num in image_matrix.flatten())
        f.write(f"{image_flat}\n")
        
        # Third line: Flattened kernel matrix with one decimal place
        kernel_flat = ' '.join(f"{num:.1f}" for num in kernel_matrix.flatten())
        f.write(f"{kernel_flat}\n")

# Generate 50 test cases in the specified folder
for i in range(1, 51):
    filename = os.path.join(folder_path, f"testcase{i}.txt")
    generate_testcase(filename)
    print(f"Generated {filename}")

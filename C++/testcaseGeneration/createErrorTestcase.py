import numpy as np
import random
import os

# Define the folder path for error test cases
error_folder_path = "error_testcases"

# Create the folder if it doesn't exist
os.makedirs(error_folder_path, exist_ok=True)

# Function to generate an error test case
def generate_error_testcase(filename, error_type):
    if error_type == 1:
        # Error 1: Kernel size greater than padded image size
        N = float(random.randint(3, 7))
        M = float(random.randint(int(N) + 1, int(N) + 4))  # Ensure kernel size > padded image size
        padding = float(random.randint(0, 4))
        stride = float(random.randint(1, 3))
        image_matrix = np.round(np.random.uniform(-10, 10, (int(N), int(N))), 1)
        kernel_matrix = np.round(np.random.uniform(-10, 10, (int(M), int(M))), 1)

    elif error_type == 2:
        # Error 2: Incorrect number of elements in the image matrix
        N = float(random.randint(3, 7))
        M = float(random.randint(2, 4))
        padding = float(random.randint(0, 4))
        stride = float(random.randint(1, 3))
        image_size = int(N) * int(N)
        incorrect_image_size = random.choice([image_size - 2, image_size + 3])  # Invalid size
        kernel_matrix = np.round(np.random.uniform(-10, 10, (int(M), int(M))), 1)
        image_matrix = np.round(np.random.uniform(-10, 10, incorrect_image_size), 1)  # Incorrect size

    elif error_type == 3:
        # Error 3: Incorrect number of elements in the kernel matrix
        N = float(random.randint(3, 7))
        M = float(random.randint(2, 4))
        padding = float(random.randint(0, 4))
        stride = float(random.randint(1, 3))
        kernel_size = int(M) * int(M)
        incorrect_kernel_size = random.choice([kernel_size - 1, kernel_size + 2])  # Invalid size
        image_matrix = np.round(np.random.uniform(-10, 10, (int(N), int(N))), 1)
        kernel_matrix = np.round(np.random.uniform(-10, 10, incorrect_kernel_size), 1)  # Incorrect size

    elif error_type == 4:
        # Error 4: N, M, padding, or stride out of allowed range
        N = float(random.choice([2, 8]))  # Invalid value for N
        M = float(random.choice([1, 5]))  # Invalid value for M
        padding = float(random.choice([-1, 5]))  # Invalid value for padding
        stride = float(random.choice([0, 4]))  # Invalid value for stride
        image_matrix = np.round(np.random.uniform(-10, 10, (3, 3)), 1)  # Default valid size
        kernel_matrix = np.round(np.random.uniform(-10, 10, (2, 2)), 1)  # Default valid size

    # Write to the file
    with open(filename, 'w') as f:
        # First line: N, M, padding, and stride with one decimal place
        f.write(f"{N:.1f} {M:.1f} {padding:.1f} {stride:.1f}\n")

        if error_type == 2:
            # Second line: Incorrect image matrix
            image_flat = ' '.join(f"{num:.1f}" for num in image_matrix)
            f.write(f"{image_flat}\n")
        else:
            # Second line: Flattened image matrix with one decimal place
            image_flat = ' '.join(f"{num:.1f}" for num in image_matrix.flatten())
            f.write(f"{image_flat}\n")

        if error_type == 3:
            # Third line: Incorrect kernel matrix
            kernel_flat = ' '.join(f"{num:.1f}" for num in kernel_matrix)
            f.write(f"{kernel_flat}\n")
        else:
            # Third line: Flattened kernel matrix with one decimal place
            kernel_flat = ' '.join(f"{num:.1f}" for num in kernel_matrix.flatten())
            f.write(f"{kernel_flat}\n")


# Generate error test cases
for i in range(1, 21):
    error_type = random.randint(1, 4)  # Randomly pick an error type
    filename = os.path.join(error_folder_path, f"testcase{i}.txt")
    generate_error_testcase(filename, error_type)
    print(f"Generated {filename} with error type {error_type}")

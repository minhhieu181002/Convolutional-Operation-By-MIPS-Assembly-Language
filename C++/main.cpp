#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip>
#include <cmath>
#include <cstdlib>
using namespace std;

// Function to log errors to a file
void logError(const string &errorMessage, const string &outputFilename) {
    ofstream errorFile(outputFilename);

    if (!errorFile) {
        cerr << "Error: Unable to open error log file: " << outputFilename << endl;
        exit(EXIT_FAILURE);
    }

    errorFile << "Error: " << errorMessage << endl;
    cerr << "Error logged to: " << outputFilename << endl;

    errorFile.close();
}

// Function to validate the input values
void validateInput(float N, float M, float padding, float stride, const string &outputFilename) {
    if (N < 3 || N > 7) {
        string errorMessage = "N (image size) must be between 3 and 7.";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }
    if (M < 2 || M > 4) {
        string errorMessage = "M (kernel size) must be between 2 and 4.";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }
    if (padding < 0 || padding > 4) {
        string errorMessage = "Padding must be between 0 and 4.";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }
    if (stride < 1 || stride > 3) {
        string errorMessage = "Stride must be between 1 and 3.";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }
}

void validateMatrixSize(const vector<vector<float>> &matrix, int expectedSize, const string &matrixName, const string &outputFilename) {
    int totalElements = 0;

    // Calculate the total number of elements in the matrix
    for (const auto &row : matrix) {
        totalElements += row.size(); // Add up the number of elements in each row
    }
    cout << "Total elements: " << totalElements << endl;
    // Check if the total number of elements matches expected size
    int expectedElements = expectedSize * expectedSize;
    cout << "expectedElements: " << expectedElements << endl;
    if (totalElements != expectedElements) {
        string errorMessage = matrixName + " matrix has incorrect number of elements. Expected: " + to_string(expectedElements) +
                              ", Got: " + to_string(totalElements);
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }

    // Ensure all rows have the correct size
    for (const auto &row : matrix) {
        if (row.size() != expectedSize) {
            string errorMessage = matrixName + " matrix row has incorrect number of elements. Expected: " + to_string(expectedSize) +
                                  ", Got: " + to_string(row.size());
            logError(errorMessage, outputFilename);
            exit(EXIT_FAILURE);
        }
    }
}


// Function to check if kernel size is valid for the padded image
void validateKernelFitsImage(int imageSize, int kernelSize, const string &outputFilename) {
    if (kernelSize > imageSize) {
        string errorMessage = "Kernel size (" + to_string(kernelSize) + ") exceeds image size (" + to_string(imageSize) + ").";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }
}

// Function to read the input file
void readInputFile(const string &filename, float &N, float &M, float &padding, float &stride, vector<vector<float>> &image, vector<vector<float>> &kernel, const string &outputFilename) {
    ifstream inputFile(filename);

    if (!inputFile) {
        string errorMessage = "Error opening input file: " + filename;
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }

    // Read the first line: N, M, padding, and stride
    inputFile >> N >> M >> padding >> stride;

    // Validate the input values
    validateInput(N, M, padding, stride, outputFilename);

    // Resize the image matrix to NxN
    image.resize(N, vector<float>(N));

    // Read the image matrix elements
    int imageElementsRead = 0;
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            if (!(inputFile >> image[i][j])) {
                string errorMessage = "Error: Image matrix has fewer elements than expected (N × N).";
                logError(errorMessage, outputFilename);
                exit(EXIT_FAILURE);
            }
            imageElementsRead++;
        }
    }

    // Check if there are extra elements for the image matrix
    if (imageElementsRead != N * N) {
        string errorMessage = "Error: Image matrix has extra elements beyond expected size (N × N).";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }

    // Resize the kernel matrix to MxM
    kernel.resize(M, vector<float>(M));

    // Read the kernel matrix elements
    int kernelElementsRead = 0;
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < M; ++j) {
            if (!(inputFile >> kernel[i][j])) {
                string errorMessage = "Error: Kernel matrix has fewer elements than expected (M × M).";
                logError(errorMessage, outputFilename);
                exit(EXIT_FAILURE);
            }
            kernelElementsRead++;
        }
    }

    // Check if there are extra elements for the kernel matrix
    if (kernelElementsRead != M * M) {
        string errorMessage = "Kernel matrix has extra elements beyond expected size (M × M).";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }

    // Validate that there are no extra data left unread in the file
    float extraValue;
    if (inputFile >> extraValue) {
        string errorMessage = "Extra data found in the input file beyond the required matrix elements.";
        logError(errorMessage, outputFilename);
        exit(EXIT_FAILURE);
    }

    inputFile.close();
}

// Function to perform the dot product of the image sub-matrix and kernel matrix
float dotProduct(const vector<vector<float>> &image, const vector<vector<float>> &kernel, int startRow, int startCol) {
    int kernelSize = kernel.size();
    float sum = 0.0f;

    // Perform element-wise multiplication and summation
    for (int i = 0; i < kernelSize; ++i) {
        for (int j = 0; j < kernelSize; ++j) {
            sum += image[startRow + i][startCol + j] * kernel[i][j];
        }
    }

    return sum;
}

// Function to perform the convolution operation
vector<vector<float>> convolve(const vector<vector<float>> &image, const vector<vector<float>> &kernel, float padding, float stride, float oldSize) {
    int kernelSize = kernel.size();
    int outputSize = ((oldSize + 2 * padding - kernelSize) / stride) + 1;
    vector<vector<float>> output(outputSize, vector<float>(outputSize, 0.0f));

    // Loop through the image matrix to apply the kernel
    for (int i = 0; i < outputSize; ++i) {
        for (int j = 0; j < outputSize; ++j) {
            int startRow = i * stride;
            int startCol = j * stride;

            // Perform the dot product and store the result in the output matrix
            output[i][j] = dotProduct(image, kernel, startRow, startCol);
        }
    }

    return output;
}

// Function to add padding to the image matrix
vector<vector<float>> addPadding(const vector<vector<float>> &image, int padding) {
    int N = image.size(); // Original image size
    int newSize = N + 2 * padding; // New size after adding padding
    float paddingValue = 0.0f; // Value to be used for padding
    vector<vector<float>> paddedImage(newSize, vector<float>(newSize, paddingValue));

    // Copy the original image into the center of the padded image
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            paddedImage[i + padding][j + padding] = image[i][j];
        }
    }

    return paddedImage;
}

void printMatrix(const vector<vector<float>> &matrix) {
    for (const auto &row : matrix) {
        for (float val : row) {
            cout << val << " ";
        }
        cout << endl;
    }
}

float roundToOneDecimal(float value) {
    // Multiply by 10, round, then divide by 10
    return std::round(value * 10.0f) / 10.0f;
}

void roundMatrix(vector<vector<float>> &matrix) {
    for (auto &row : matrix) {
        for (auto &val : row) {
            val = roundToOneDecimal(val);
        }
    }
}

void writeToFile(const string &filename, const vector<vector<float>> &matrix) {
    ofstream outputFile(filename);

    if (!outputFile) {
        cerr << "Error opening output file!" << endl;
        return;
    }

    // Set output format to fixed and one decimal place
    outputFile << std::fixed << std::setprecision(1);

    for (size_t i = 0; i < matrix.size(); ++i) {
        for (size_t j = 0; j < matrix[i].size(); ++j) {
            outputFile << matrix[i][j];
            if (i != matrix.size() - 1 || j != matrix[i].size() - 1) {
                outputFile << " ";
            }
        }
    }

    outputFile.close();
}

int main() {
    int start, end;
    cout << "Enter the start and end of the test cases: ";
    cin >> start >> end;

    for (int testCaseNum = start; testCaseNum <= end; ++testCaseNum) {
        float N, M, padding, stride;
        vector<vector<float>> image, kernel;

        string inputFilename = "testcaseGeneration/error_testcases/testcase" + to_string(testCaseNum) + ".txt";
        string outputFilename = "errorOutput/output" + to_string(testCaseNum) + ".txt";

        try {
            // Read the input file
            readInputFile(inputFilename, N, M, padding, stride, image, kernel, outputFilename);

            // Add padding to the image matrix
            vector<vector<float>> paddedImage = addPadding(image, padding);

            // Perform convolution
            vector<vector<float>> output = convolve(paddedImage, kernel, padding, stride, N);

            // Round the values in the output matrix
            roundMatrix(output);

            // Write the result to the output file
            writeToFile("errorOutput/output" + to_string(testCaseNum) + ".txt", output);
            cout << "Processed " << inputFilename << " and saved to output file." << endl;

        } catch (const exception &e) {
            cerr << "Exception occurred: " << e.what() << endl;
        }
    }

    return 0;
}
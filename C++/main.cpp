#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip>
#include <cmath>
using namespace std;

// Function to read the input file
void readInputFile(const string &filename, float &N, float &M, float &padding, float &stride, vector<vector<float>> &image, vector<vector<float>> &kernel) {
    ifstream inputFile(filename);
    
    // Check if the file is opened successfully
    if (!inputFile) {
        cerr << "Error opening input file!" << endl;
        return;
    }

    // Read the first line: N, M, padding, and stride
    inputFile >> N >> M >> padding >> stride;

    // Resize the image matrix to NxN
    image.resize(N, vector<float>(N));

    // Read the image matrix elements
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            inputFile >> image[i][j];
        }
    }

    // Resize the kernel matrix to MxM
    kernel.resize(M, vector<float>(M));

    // Read the kernel matrix elements
    for (int i = 0; i < M; ++i) {
        for (int j = 0; j < M; ++j) {
            inputFile >> kernel[i][j];
        }
    }

    inputFile.close();  // Close the input file
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
    // int imageSize = image.size();
    // int oldSize = 6;
    cout << "imageSize: " << oldSize << endl;
    int kernelSize = kernel.size();
    cout << "kernelSize: " << kernelSize << endl;
    // Calculate the size of the output matrix
    int outputSize = ((oldSize + 2 * padding - kernelSize) / stride) + 1;
    vector<vector<float>> output(outputSize, vector<float>(outputSize, 0.0f));
    cout << "outputSize: " << outputSize << endl;
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
    // Initialize the padded image with the padding value
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
    // Loop through 50 test cases
    int start, end;
    cout << "Enter the start and end of the test cases: ";
    cin >> start >> end;
    for (int testCaseNum = start; testCaseNum <= end; ++testCaseNum) {
        float N, M, padding, stride;
        float oldSize;
        vector<vector<float>> image, kernel;

        // Prepare filenames
        string inputFilename = "testcaseGeneration/testcases/testcase" + to_string(testCaseNum) + ".txt";
        string outputFilename = "output/output" + to_string(testCaseNum) + ".txt";

        // Read the input file
        readInputFile(inputFilename, N, M, padding, stride, image, kernel);

        oldSize = N; // Store the original size of the image matrix

        // Add padding to the image matrix
        vector<vector<float>> paddedImage = addPadding(image, padding);

        // Perform convolution
        vector<vector<float>> output = convolve(paddedImage, kernel, padding, stride, oldSize);
        cout << "output before rounding: " << endl;
        printMatrix(output);
        // Round the values in the output matrix to one decimal place
        roundMatrix(output);
        // print after rounding matrix
        cout << "output after rounding: " << endl;
        printMatrix(output);
        // Write the result to the output file
        writeToFile(outputFilename, output);

        cout << "Processed " << inputFilename << " and saved to " << outputFilename << endl;
    }

    return 0;
}

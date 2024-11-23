#include <iostream>
#include <string>
#include <cuda_runtime.h>

using namespace std;

// Kernel running on the GPU
__global__ void encryptCaesar(char *d_input, char *d_output, int shift, int length) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    // Print debug message from the GPU
    if (idx == 0) {
        printf("Running encryption on the GPU...\n");
    }

    if (idx < length) {
        // Encrypt each character
        char c = d_input[idx];

        // Check if the character is an uppercase letter
        if (c >= 'A' && c <= 'Z') {
            d_output[idx] = (c - 'A' + shift) % 26 + 'A';
        }
        // Check if the character is a lowercase letter
        else if (c >= 'a' && c <= 'z') {
            d_output[idx] = (c - 'a' + shift) % 26 + 'a';
        }
        else {
            // Non-alphabetical characters remain the same
            d_output[idx] = c;
        }
    }
}

int main() {
    string input;
    int shift;

    // Ask user for input string and shift value
    cout << "Enter the string to encrypt: ";
    getline(cin, input);
    cout << "Enter the shift value for Caesar cipher (1-25): ";
    cin >> shift;

    // CPU message
    cout << "Running setup and memory allocation on the CPU...\n";

    int length = input.length();
    char *d_input, *d_output;

    // Allocate memory on the CPU (host)
    char *h_input = new char[length + 1];
    char *h_output = new char[length + 1];  // Include null terminator for safety

    // Copy the input string to the host memory
    strcpy(h_input, input.c_str());

    // Allocate memory on the GPU (device)
    cudaMalloc((void **)&d_input, length * sizeof(char));
    cudaMalloc((void **)&d_output, length * sizeof(char));

    // Copy data from CPU to GPU
    cudaMemcpy(d_input, h_input, length * sizeof(char), cudaMemcpyHostToDevice);

    // Define the block size and grid size
    int blockSize = 256;
    int gridSize = (length + blockSize - 1) / blockSize;

    // Launch the kernel to encrypt the string
    cout << "Launching kernel on the GPU...\n";
    encryptCaesar<<<gridSize, blockSize>>>(d_input, d_output, shift, length);

    // Wait for GPU to finish
    cudaDeviceSynchronize();

    // Copy the result back to host memory
    cudaMemcpy(h_output, d_output, length * sizeof(char), cudaMemcpyDeviceToHost);

    // Add null terminator to output string
    h_output[length] = '\0';

    // Print the encrypted string
    cout << "Encrypted string: " << h_output << endl;

    // CPU message
    cout << "Cleaning up GPU memory on the CPU...\n";

    // Free the allocated GPU memory
    cudaFree(d_input);
    cudaFree(d_output);

    // Free the allocated CPU memory
    delete[] h_input;
    delete[] h_output;

    return 0;
}

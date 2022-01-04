#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <ctime>
#include <float.h>
#include "mypgm.h"

//kernel: funkcija koju izvtrsavaju niti GPUa

__global__ void sobel_gpu(float* image1, float* image2, int w, int h) {

    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    float dx, dy;

    if (x > 0 && y > 0 && x < w - 1 && y < h - 1){


        dy = (image1[(y - 1) * w + (x - 1)]) + (2 * image1[(y - 1) * w + x]) + (image1[(y - 1) * w + (x + 1)]) +
            (-1 * image1[(y + 1) * w + (x - 1)]) + (-2 * image1[(y + 1) * w + x]) + (-1 * image1[(y + 1) * w + (x + 1)]);

        dx = (-1 * image1[(y - 1) * w + (x - 1)]) + (-2 * image1[y * w + (x - 1)]) 
            + (-1 * image1[(y + 1) * w + (x - 1)]) + (image1[(y - 1) * w + (x + 1)]) 
            + (2 * image1[y * w + (x + 1)]) + (image1[(y + 1) * w + (x + 1)]);

       

        image2[y * w + x] = sqrt((dx * dx) + (dy * dy));
    }
}

//host: funkcija koja se izvršava na procesoru

__host__ void sobel_cpu(float image1[1024][1024], float image3[1024][1024], int w, int h) {

    float dx, dy;

    for (int i = 0; i < w-2; i++) {
        for (int j = 0; j < h-2; j++) {

           
                dy = (-1 * image1[i][j]) + (-2 * image1[i][j+1]) + (-1 * image1[i][j+2]) +
                    (1 * image1[i+2][j]) + (2 * image1[i+2][j+1]) + (image1[i+2][j+2]);


                dx = (-1 * image1[i][j]) + (1 * image1[i][j + 2])
                    + (-2* image1[i+1][j]) + (2 * image1[i+1][j+2])
                    + (-1 * image1[i+2][j]) + (1 * image1[i+2][j+2]);

                image3[i][j] = sqrt((dx * dx) + (dy * dy));
        }
    }
}

int main() {

    //Ucitavanje Slike (slika image1 je globalna varijabla radi jednostavnosti)
    load_image_data();

    int i, j;

    float* deviceInputImageData;
    float* deviceOutputImageData;

    //Alociranje memorije na grafickoj kartici
    cudaMalloc((void**)&deviceInputImageData, x_size1 * y_size1 * sizeof(float));
    cudaMalloc((void**)&deviceOutputImageData, x_size1 * y_size1 * sizeof(float));

    //kopiranje vrijednosti sa glavne memorije na memoriju grafičke kartice
    cudaMemcpy(deviceInputImageData, image1, x_size1 * y_size1 * sizeof(float), cudaMemcpyHostToDevice);

    //Inicijaliziramo sat da možemo pratiti vrijeme izvrsavanja GPUa
    std::clock_t start_gpu;
    double duration_gpu;
    start_gpu = std::clock();

    printf("                        ----------- GPU -----------\n");

    //Popunjavanje matrice2 (nove slike)//
    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
    printf("INICIALIZACIJA image2 (SLIKE_GPU)\n");
    x_size2 = x_size1;
    y_size2 = y_size1;
    for (i = 0; i < y_size2; i++) {
        for (j = 0; j < x_size2; j++) {
            image2[i][j] = 0;
        }
    }

    dim3  threadsPerBlock(16, 16);  //1024x1024
    dim3  numBlocks(64, 64);        //16*64 = 1024  /32*32

    printf("\nPOCETAK: Sobel filtra na GPU\n");
    //Funkcija <<<dimGrid, dimBlock>>>
    sobel_gpu<<<numBlocks, threadsPerBlock>>>(deviceInputImageData, deviceOutputImageData, x_size1, y_size1);

    //Završetak sata GPU 
    duration_gpu = (std::clock() - start_gpu) / (double)CLOCKS_PER_SEC;
    std::cout << "\nZAVRSETAK: Sobel filtra na GPU:    " << duration_gpu << "s   -   USPIJEH!" << '\n';
    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n");

    //kopiranje vrijednosti sa grafičke kartice u glavnu memoriju
    cudaMemcpy(image2, deviceOutputImageData, x_size2 * y_size2 * sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(deviceInputImageData);
    cudaFree(deviceOutputImageData);

    save_image_data_img2();

    //inicijaliziramo sat da možemo pratiti vrijeme izvrsavanja CPUa
    std::clock_t start_cpu;
    double duration_cpu;
    start_cpu = std::clock();

    printf("                        ----------- CPU -----------\n");

    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
    printf("INICIALIZACIJA image3 (SLIKE_CPU)\n");
    x_size3 = x_size1;
    y_size3 = y_size1;
    for (i = 0; i < y_size3; i++) {
        for (j = 0; j < x_size3; j++) {
            image3[i][j] = 0;
        }
    }

    printf("\nPOCETAK: Sobel filtra na CPU\n");

    sobel_cpu(image1, image3, x_size3, y_size3);

    ////Završetak sata CPU 
    duration_cpu = (std::clock() - start_cpu) / (double)CLOCKS_PER_SEC;
    std::cout << "\nZAVRSETAK: Sobel filtra na CPU:   " << duration_cpu << "s   -   USPIJEH!" << '\n';
    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n");

    //Razlika u vremenu izvršavanja:
    double duration;
    double times;

    duration = duration_cpu - duration_gpu;
    times = duration_cpu / duration_gpu * 100;

    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    std::cout << "\nRAZLIKA VREMENA IZVRSAVANJA CPU - GPU:  " << duration << '\n';
    std::cout << "\nGPU je BRZI od CPUa za:  " << times << " %" << '\n';
    printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n");
    
    save_image_data_img3();

    return 0;
}


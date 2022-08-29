#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define DATA_OFFSET_OFFSET 0xAl
#define WIDTH_OFFSET 0X12
#define HEIGHT_OFFSET 0X16
#define BITS_PER_PIXEL_OFFSET 0x1C

#define OUTPUT_FILE "images/output.bmp"
#define INPUT_FILE "images/image.bmp"


void filter(void *img, int width, int height, unsigned char *mtx);
void writeFile(char * filename, unsigned int width, unsigned int height, unsigned int bytesPerPixel, unsigned int dataOffset, void* data, void* wholeHeader);
void readFile(char* filename, unsigned int* width, unsigned int* height, unsigned int* bytesPerPixel, unsigned int* dataOffset, void** data, void** wholeHeader);

int main() {
    unsigned char mtx[9] = {10, 15, 10, 15, 156, 15, 10, 15, 10};
    unsigned char mtx4[9] = {0, -1, 0, -1, 4, -1, 0, -1, 0};
    unsigned char mtx6[9] = {28, 28, 28, 28, 28, 28, 28, 28, 28};
    
    unsigned char* matrix = mtx;
    
    unsigned int width;
    unsigned int height;
    unsigned int bytesPerPixel;
    unsigned int dataOffset;
    void* wholeHeader = NULL;
    void* data = NULL;
    readFile(INPUT_FILE, &width, &height, &bytesPerPixel, &dataOffset, &data, &wholeHeader);
    if(data == NULL) {
        return 1;
    }

    filter(data, width, height, matrix);

    writeFile(OUTPUT_FILE, width, height, bytesPerPixel, dataOffset, data, wholeHeader);
    
    free(data);
    free(wholeHeader);
    return 0;
}

void writeFile(char * filename, unsigned int width, unsigned int height, unsigned int bytesPerPixel, unsigned int dataOffset, void* data, void* wholeHeader){
    //write data to the file
    FILE* outputFile = fopen(filename, "wb");
    if(!outputFile) {
        printf("Cannot open output file.\n");
        return;
    }
    int size = width * height;

    int paddedRowSize = ceil((width * bytesPerPixel / 4.0)) * 4;
    int unpaddedRowSize = width * bytesPerPixel;

    fwrite(wholeHeader, dataOffset, 1, outputFile);

    void* dataPointer = data;
    char zero = 0;
    for (int x = 0; x < height; x++){
        fwrite(dataPointer, 1, unpaddedRowSize, outputFile);

        // saves zeros to make padding
        for(int y = 0; y < paddedRowSize - unpaddedRowSize; y++) {
            fwrite(&zero, 1, 1, outputFile);
        }
        dataPointer += unpaddedRowSize;
    }

    fclose(outputFile);
}

void readFile(char* filename, unsigned int* width, unsigned int* height, unsigned int* bytesPerPixel, unsigned int* dataOffset, void** data, void** wholeHeader){
    FILE *image = fopen(filename, "rb");
    if(!image) {
        printf("Unable to open file\n");
        return;
    }

    char header[2];
    short bitsPerPixel;

    // Read informations about .bmp file
    fread(&header, 1, 2, image);
    if(header[0] != 'B' || header[1] != 'M') {
        printf("Program supports only bitmap files.\n");
        return;
    }

    fseek(image, DATA_OFFSET_OFFSET, SEEK_SET);
    fread(dataOffset, 4, 1, image);

    fseek(image, WIDTH_OFFSET, SEEK_SET);
    fread(width, 4, 1, image);

    fseek(image, HEIGHT_OFFSET, SEEK_SET);
    fread(height, 4, 1, image);

    fseek(image, BITS_PER_PIXEL_OFFSET, SEEK_SET);
    fread(&bitsPerPixel, 2, 1, image);

    *bytesPerPixel = bitsPerPixel / 8;
    int paddedRowSize = ceil((*width * *bytesPerPixel / 4.0)) * 4;
    int unpaddedRowSize = *width * *bytesPerPixel;
    if(*bytesPerPixel != 3) {
        printf("Program supports only 24bpp bitmap files.\n");
        return;
    }

    *wholeHeader = malloc(*dataOffset);
    fseek(image, 0, SEEK_SET);
    fread(*wholeHeader, *dataOffset, 1, image);

    // allocate memory for data
    int size = *width * *height;
    *data = malloc(size * 3);

    void* dataPointer = *data;
    for (int x = 0; x < *height; x++){
        int offset = *dataOffset + x * paddedRowSize;
        fseek(image, offset, SEEK_SET);
        fread(dataPointer, 1, unpaddedRowSize, image);
        dataPointer += unpaddedRowSize;
    }

    fclose(image);
}
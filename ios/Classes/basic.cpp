
#include <stdlib.h>
#include <opencv2/opencv.hpp>

#include "basic.h"

#include <android/log.h>


using namespace cv;
using namespace std;

// Avoiding name mangling
extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    __attribute__((visibility("default"))) __attribute__((used))
    int process_frame(uint8_t* pixels, int width, int height, uint8_t* destinationMatrix) {
        Mat input = Mat(height, width, CV_8UC3, (unsigned char*)pixels);
        //cvtColor(input, destinationMatrix, CV_YUV2BGR_YUV420);
        /*
        Mat threshed, withContours;

        vector<vector<Point>> contours;
        vector<Vec4i> hierarchy;

        adaptiveThreshold(input, threshed, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 77, 6);
        findContours(threshed, contours, hierarchy, RETR_TREE, CHAIN_APPROX_TC89_L1);

        cvtColor(threshed, withContours, COLOR_GRAY2BGR);
        drawContours(withContours, contours, -1, Scalar(0, 255, 0), 4);

        destinationMatrix = withContours.clone().data; */
        //destinationMatrix = input.clone().data;
        return 1;
    }
}

int clamp(int lower, int higher, int val){
    if(val < lower)
        return 0;
    else if(val > higher)
        return 255;
    else
        return val;
}

int getRotatedImageByteIndex(int x, int y, int rotatedImageWidth){
    return rotatedImageWidth*(y+1)-(x+1);
}
extern "C" {
    __attribute__((visibility("default"))) __attribute__((used))
    int convert_image(uint8_t *plane0, uint8_t *plane1, uint8_t *plane2, int bytesPerRow, int bytesPerPixel, int width, int height, uint32_t* image){
        int hexFF = 255;
        int uvIndex, index;
        int yp, up, vp;
        int r, g, b;
        int rt, gt, bt;

        for(int x = 0; x < width; x++){
            for(int y = 0; y < height; y++){

                uvIndex = bytesPerPixel * ((int) floor(x/2)) + bytesPerRow * ((int) floor(y/2));
                index = y*width+x;

                yp = plane0[index];
                up = plane1[uvIndex];
                vp = plane2[uvIndex];
                rt = round(yp + vp * 1436 / 1024 - 179);
                gt = round(yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91);
                bt = round(yp + up * 1814 / 1024 - 227);
                r = clamp(0, 255, rt);
                g = clamp(0, 255, gt);
                b = clamp(0, 255, bt);
                image[getRotatedImageByteIndex(y, x, height)] = (hexFF << 24) | (b << 16) | (g << 8) | r;
            }
        }

        //__android_log_print(ANDROID_LOG_DEBUG, "flutter", "Obrazek1: %i",image[0]);
        //uint32_t* initData = (uint32_t*)calloc(1, sizeof(uint32_t) * height * width);
        //Mat foo(height,width, CV_8UC4, initData);

/*
        Mat obrazek(width, height, CV_8UC4, image);
        Mat grey;
        cvtColor(obrazek, grey, COLOR_BGRA2RGBA);
        memcpy(image, grey.data, 4 * (width * height));
  */

        // laplace:
        Mat imageAsMat(width, height, CV_8UC4, image);
        Mat outputMat, imageGrayAsMat, bufferMat;
        GaussianBlur( imageAsMat, imageAsMat, Size(3, 3), 0, 0, BORDER_DEFAULT );
        cvtColor( imageAsMat, imageGrayAsMat, COLOR_BGRA2GRAY );
        Laplacian( imageGrayAsMat, outputMat, CV_16S, 3, 1, 0, BORDER_DEFAULT );

        convertScaleAbs( outputMat, bufferMat );

        cvtColor( bufferMat, outputMat, COLOR_GRAY2BGRA );

        memcpy(image, outputMat.data, 4 * (width * height));

        //memcpy(image, initData, 4 * (width * height));
        //__android_log_print(ANDROID_LOG_DEBUG, "flutter", "Obrazek2: %i",image[0]);
        //free(initData);

        return 1;
    }
}

extern "C" {
    __attribute__((visibility("default"))) __attribute__((used))
    uint32_t get_first_plane(uint8_t *plane0, uint8_t *plane1, uint8_t *plane2, int bytesPerRow, int bytesPerPixel, int width, int height, uint32_t* image){
        //uint32_t *image = (uint32_t*)malloc(sizeof(uint32_t) * (width * height));
        int x, y, index;
        int yp;
        for(x = 0; x < width; x++){
                    for(y = 0; y < height; y++){
                        index = y*width+x;

                        yp = plane0[index];
                        image[getRotatedImageByteIndex(y, x, height)] = yp;
                    }
                }
        return 1;
    }
}                                      
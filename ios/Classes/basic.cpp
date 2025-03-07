
#include <stdlib.h>
#include <opencv2/opencv.hpp>

#include "basic.h"

#include <android/log.h>

using namespace cv;
using namespace std;

int clamp(int low, int high, int val){
    if(val < low)
        return 0;
    else if(val > high)
        return 255;
    else
        return val;
}

int getRotatedImageByteIndex(int x, int y, int rotatedImageWidth){
    return rotatedImageWidth*(y+1)-(x+1);
}
// Avoiding name mangling
extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
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
        // laplace:
        Mat imageAsMat(width, height, CV_8UC4, image);
        Mat outputMat, imageGrayAsMat, bufferMat;
        GaussianBlur( imageAsMat, imageAsMat, Size(3, 3), 0, 0, BORDER_DEFAULT );
        cvtColor( imageAsMat, imageGrayAsMat, COLOR_BGRA2GRAY );
        Laplacian( imageGrayAsMat, outputMat, CV_16S, 3, 1, 0, BORDER_DEFAULT );

        convertScaleAbs( outputMat, bufferMat );

        cvtColor( bufferMat, outputMat, COLOR_GRAY2BGRA );

        memcpy(image, outputMat.data, 4 * (width * height));

        return 1;
    }
}                                  
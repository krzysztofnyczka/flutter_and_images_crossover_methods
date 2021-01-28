cmake_minimum_required(VERSION 3.6.0)

project(praca_inzynierska VERSION 1.0)

include_directories(../include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)
set(SCRIPTS_PATH "../ios/Classes")
set(SOURCES
    ${SCRIPTS_PATH}/basic.cpp
)
find_library( # Defines the name of the path variable that stores the location of the NDK library.
              log-lib

              # for logging purpuses
              log )
add_library(opencv_binding SHARED ${SOURCES})
target_link_libraries(opencv_binding lib_opencv
${log-lib})
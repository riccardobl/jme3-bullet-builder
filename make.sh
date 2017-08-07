#!/bin/bash
# Author: Riccardo Balbo
# License: 
# Copyright (c) 2017, Riccardo Balbo
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this 
# list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
# THE POSSIBILITY OF SUCH DAMAGE.

# Configurations
source thirdparty/bash_colors.sh
source buildlist.sh

export JDK_ROOT="$JAVA_HOME"
export READ_LINK="readlink"
if [ "`which greadlink`" != "" ]; 
then
    echo "Use greadlink"
    export READ_LINK="greadlink"  
fi
export JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/Commands/java::")"
if [ ! -f "$JDK_ROOT/Headers/jni.h" ];
then
    export JDK_ROOT="$JAVA_HOME"
    if [ ! -f "$JDK_ROOT/include/jni.h" ];
    then
        export JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/bin/java::")"
        if [ ! -f "$JDK_ROOT/include/jni.h" ];
        then
            export JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/jre/bin/java::")"
            if [ ! -f "$JDK_ROOT/include/jni.h" ];
            then
                echo "Can't find JDK"
            fi
        fi
    fi
fi
mkdir -p build

function cleanTMP {
    rm -Rf build/tmp
    mkdir -p build/tmp
}
function clean {
    rm -R build
    mkdir build
}
function setPlatformArch {
    export PLATFORM=$1
    export ARCH=$2
    export OUT_PATH="$PWD/build/lib/$SUB_VERSION/native/$PLATFORM/$ARCH"
    mkdir -p $OUT_PATH
}
function findCppFiles { #Find .cpp and header paths that need to be passed to g++
    echo "">build/tmp/cpplist.txt
    find  build/tmp/bullet/src/BulletCollision -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/BulletDynamics -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/BulletInverseDynamics -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/BulletSoftBody -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/LinearMath -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/clew -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/$REPO_HASH/jme3-bullet-native/src/native/cpp/ -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/bullet/src/Bullet3Common -type f -name '*.cpp' >> build/tmp/cpplist.txt
    
    
    find  build/tmp/bullet/src/BulletCollision -type d  >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/BulletDynamics -type d  >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/BulletInverseDynamics -type d >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/BulletSoftBody -type d  >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/LinearMath -type d  >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/clew -type d  >> build/tmp/Ilist.txt
    find  build/tmp/bullet/src/Bullet3Common -type d  >> build/tmp/Ilist.txt


    # For <=2.82
    #find  build/tmp/bullet/src/vectormath -type f -name '*.cpp' >> build/tmp/cpplist.txt
    #find  build/tmp/bullet/src/vectormath -type d  >> build/tmp/Ilist.txt
    #find  build/tmp/bullet/src/BulletMultiThreaded -type f -name '*.cpp' >> build/tmp/cpplist.txt
    #find  build/tmp/bullet/src/BulletMultiThreaded  -type d  >> build/tmp/Ilist.txt
    
    for line in $(cat  build/tmp/Ilist.txt); do
        echo "-I$line " >>  build/tmp/IIlist.txt
    done
}

#Build scripts
function buildLinux {
    setPlatformArch "linux" $1
    clr_green "Compile for $PLATFORM $ARCH..."
    arch_flag="-m64"
    if [ "$1" = "x86" ];
    then
        arch_flag="-m32"
    fi
    findCppFiles
    
    args="-O3"
    if [ "$DEBUG" == "1" ];
    then
        args="-g -O1"
    fi
    
    build_script="
    g++ -mtune=generic -DBT_NO_PROFILE=1 -fpermissive -U_FORTIFY_SOURCE $args  -fPIC  $arch_flag -shared
    -Ibuild/tmp/bullet/src/
    -I$JDK_ROOT/include
    -I$JDK_ROOT/include/linux
    -Ibuild/tmp/$REPO_HASH/jme3-bullet-native/src/native/cpp
    $(cat  build/tmp/IIlist.txt)
    $(cat build/tmp/cpplist.txt)
    -Wl,-soname,bulletjme.so -o $OUT_PATH/libbulletjme.so  -lrt"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}

function buildWindows {
    setPlatformArch "windows" $1
    clr_green "Compile for $PLATFORM $ARCH..."
    compiler="x86_64-w64-mingw32-g++"
    arch_flag="-DWIN64"
    # "-m64"
    if [ "$1" = "x86" ];
    then
        arch_flag=""
        compiler="i686-w64-mingw32-g++"
    fi
    findCppFiles
    
    args="-Ofast "
    if [ "$DEBUG" == "1" ];
    then
        args="-g -O1"
    fi
    
    
    build_script="
    $compiler $arch_flag -mtune=generic -DBT_NO_PROFILE=1 -fpermissive -fPIC   -U_FORTIFY_SOURCE $args  -DWIN32  -shared
    -Ibuild/tmp/bullet/src/
    -I$JDK_ROOT/include
    -Ibuild/tmp/win
    -Ibuild/tmp/$REPO_HASH/jme3-bullet-native/src/native/cpp  -static
    $(cat  build/tmp/IIlist.txt)
    $(cat build/tmp/cpplist.txt) -Wp,-w
    -Wl,--exclude-all-symbols,--add-stdcall-alias,--kill-at,-soname,bulletjme.dll  -o $OUT_PATH/bulletjme.dll"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}

function buildMac {
    setPlatformArch "osx" $1
    clr_green "Compile for $PLATFORM $ARCH..."
    arch_flag="-arch x86_64"
    if [ "$1" = "x86" ];
    then
        arch_flag="-arch i386"
    fi
    findCppFiles
    
    args="-Ofast "
    if [ "$DEBUG" == "1" ];
    then
        args="-g -O1"
    fi
    
    build_script="
    g++ -mtune=generic -DBT_NO_PROFILE=1 -fpermissive $arch_flag -U_FORTIFY_SOURCE -fPIC $args   -shared
    -Ibuild/tmp/bullet/src/
    -Ibuild/tmp/$REPO_HASH/jme3-bullet-native/src/native/cpp
    -I$JDK_ROOT/Headers/
    -I$JDK_ROOT/Headers/darwin
    $(cat  build/tmp/IIlist.txt)
    $(cat build/tmp/cpplist.txt)
    -o $OUT_PATH/libbulletjme.dylib"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}


function main {
    if [ "$GROUP" == "" ];
    then
        export GROUP="org.jmonkeyengine.bullet_builder"
    fi
    if [ "$VERSION" == "" ];
    then
        export VERSION="1.0"
    fi
    export SUB_VERSION=$VERSION

    if [ "$DEPLOY" == "" ];
    then
        export DEPLOY="false";
    fi
    if [ "$BUILD_WINDOWS" == "" ];
    then
        export BUILD_WINDOWS="false";
    fi
    if [ "$BUILD_LINUX" == "" ];
    then
        export BUILD_LINUX="true";
    fi
    if [ "$BUILD_MAC" == "" ];
    then
        export BUILD_MAC="false";
    fi

    if [ "$TRAVIS_COMMIT" != "" ];
    then
        export VERSION=$TRAVIS_COMMIT        
        if [ "$TRAVIS_TAG" != "" ];
        then
            echo "Deploy for $TRAVIS_TAG."
            export VERSION=$TRAVIS_TAG #Set version to tag name
            export DEPLOY="true"  #Deploy only on tags
        fi
    fi
    
    echo "Build [$1]"  
        
    if [ "$1" != "deploy" ];
    then
        OS="winLinux"
        for target in "${BUILD_LIST[@]}"
        do
            IFS=',' read -a target <<< "$target"

            export DEBUG=${target[2]}
            export SUB_VERSION="${target[0]}-$VERSION"
            export REPO_HASH=`echo "${target[3]}" | md5sum | cut -f1 -d' '`
            if [ "$DEBUG" = "1" ];
            then
                export SUB_VERSION="$SUB_VERSION-debug"
            fi
            
            if [ ! -d "build/$REPO_HASH" ]; then
                clr_green "Clone engine ${target[3]}:${target[1]} -- $REPO_HASH..."
                git clone ${target[3]} build/$REPO_HASH
                cd build/$REPO_HASH
                git checkout ${target[1]}
                cd ../../
            else
                clr_green "Update engine ${target[3]}:${target[1]} -- $REPO_HASH..."
                cd build/$REPO_HASH
                git checkout ${target[1]}
                git fetch origin 
                git reset --hard origin/${target[1]}
                cd ../../
            fi

            clr_green "Find required Bullet dl url"
            bulletUrl=`grep -m1 "bulletUrl" build/$REPO_HASH/gradle.properties|cut -d'=' -f2 | tr -d '[:space:]' | tr -dc '[[:print:]]'`
            bulletUrlHash=`echo "$bulletUrl" | md5sum | cut -f1 -d' '`

            if [ ! -f "build/$bulletUrlHash.zip" ];
            then
                echo "Download $bulletUrl in build/$bulletUrlHash.zip"
                wget   "$bulletUrl" -O build/$bulletUrlHash.zip
            else
                echo "Use $bulletUrl from cache [build/$bulletUrlHash.zip]"
            fi


            cleanTMP
            mkdir -p build/tmp/win
            cp -Rf win/* build/tmp/win/
            cp -Rf build/$REPO_HASH build/tmp/$REPO_HASH

            mkdir build/tmp/ext
            unzip -q build/$bulletUrlHash.zip -d  build/tmp/ext
            mv build/tmp/ext/* build/tmp/bullet

    

         
            if [ "$TRAVIS_OS_NAME" = "linux" -o "$OS_NAME" = "linux" ];
            then
                if [ "$BUILD_LINUX" = "true" ];
                then
                    buildLinux "x86"
                    buildLinux "x86_64"
                fi
                if [ "$BUILD_WINDOWS" = "true" ];
                then
                    buildWindows "x86"
                    buildWindows "x86_64"
                fi
            fi
            
            if [ "$TRAVIS_OS_NAME" = "osx"  -o "$OS_NAME" = "osx" ];
            then
                OS="mac"
                if [ "$BUILD_MAC" = "true" ];
                then
                    buildMac "x86"
                    buildMac "x86_64"
                fi
            fi
        done
        
        if [ "$DEPLOY" = "true" ];
        then
            #Upload build to a temporary repository
            mkdir -p deploy/
            tar -C build/lib -czf deploy/libs-$OS-$VERSION.tar.gz .
            if [ "$BINTRAY_USER" = "" ];
            then
                echo "Dry run: Upload  deploy/libs-$OS-$VERSION.tar.gz   to  https://api.bintray.com/content/riccardo/jme3-bullet-native-files/libs/$VERSION/$VERSION/"
            else
                curl -X PUT  -T  deploy/libs-$OS-$VERSION.tar.gz -u$BINTRAY_USER:$BINTRAY_API_KEY\
                "https://api.bintray.com/content/riccardo/jme3-bullet-native-files/libs/$VERSION/$VERSION/"
            fi
        fi
                
    else
        
        if [ "$DEPLOY" != "true" ];
        then
            exit 0
        fi

        rm -Rf deploy
        mkdir -p deploy/

        # Check if windows and linux builds exist
        if [ "$BINTRAY_USER" = "" ];
        then
            echo "Dry run: Check https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-winLinux-$VERSION.tar.gz"
        else
            out=`curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent --head --write-out '%{http_code}'  -o deploy/tmpl.tar.gz.h  https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-winLinux-$VERSION.tar.gz`
            if [ "$out" != "200" ];
            then
                echo "[warning] Windows and Linux libs not found. Skip deploy."
                exit 0
            fi
        fi
        
        # Check if mac build exists
        if [ "$BINTRAY_USER" = "" ];
        then
            echo "Dry run: Check https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-mac-$VERSION.tar.gz"
        else
            out=`curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent --head --write-out '%{http_code}'  -o deploy/tmpm.tar.gz.h https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-mac-$VERSION.tar.gz`
            if [ "$out" != "200" ];
            then
                echo "[warning] Mac libs not found. Skip deploy."
                exit 0
            fi
        fi

        export DEPLOY="2"
        
        # Download linux & windows builds
        if [ "$BINTRAY_USER" = "" ];
        then
            echo "Dry run: Download https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-winLinux-$VERSION.tar.gz"
            mkdir -p "/tmp/$VERSION-dryrun"
            echo "1" >  "/tmp/$VERSION-dryrun/0.txt"
            tar -czf deploy/tmpm.tar.gz -C "/tmp/$VERSION-dryrun" .
        else
            curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent  -o deploy/tmpl.tar.gz https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-winLinux-$VERSION.tar.gz
        fi


        #Download mac build
        if [ "$BINTRAY_USER" = "" ];
        then
            echo "Dry run: Download https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-mac-$VERSION.tar.gz"
            mkdir -p "/tmp/$VERSION-dryrun"
            echo "1" >  "/tmp/$VERSION-dryrun/0.txt"
            tar -czf deploy/tmpm.tar.gz -C "/tmp/$VERSION-dryrun" .
        else
            curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent  -o deploy/tmpm.tar.gz https://dl.bintray.com/riccardo/jme3-bullet-native-files/$VERSION/libs-mac-$VERSION.tar.gz
        fi

        # Build artifact
        echo "Deploy!"
        mkdir -p build/lib/
        # Merge both builds together
        tar -xzf deploy/tmpl.tar.gz -C build/lib/
        tar -xzf deploy/tmpm.tar.gz -C build/lib/

        echo "" > deploy/deploy_list.txt

        #Build jar
        for target in "${BUILD_LIST[@]}"
        do
            IFS=',' read -a target <<< "$target"

            export DEBUG=${target[2]}
            export SUB_VERSION="${target[0]}-$VERSION"
            
            if [ "$DEBUG" = "1" ];
            then
                export SUB_VERSION="$SUB_VERSION-debug"
            fi
            
            echo "$SUB_VERSION" >> deploy/deploy_list.txt


            if [ "$BINTRAY_USER" = "" ];
            then
                echo "Dry run: `which jar` cf deploy/jme3-bullet-native-$SUB_VERSION.jar -C build/lib/$SUB_VERSION ."
            else
                `which jar` cf deploy/jme3-bullet-native-$SUB_VERSION.jar -C build/lib/$SUB_VERSION .
            fi

            #Upload on bintray
            target_dir=${GROUP//./\/}
            if [ "$BINTRAY_USER" = "" ];
            then
                echo "Dry run: Upload deploy/jme3-bullet-native-$SUB_VERSION.jar  to https://api.bintray.com/content/riccardo/jme3-bullet-native/jme3-bullet-native/$SUB_VERSION/$target_dir/jme3-bullet-native/$SUB_VERSION/jme3-bullet-native-$SUB_VERSION.jar?publish=1&override=1"
            else
                curl -X PUT  -T  deploy/jme3-bullet-native-$SUB_VERSION.jar -u$BINTRAY_USER:$BINTRAY_API_KEY \
                "https://api.bintray.com/content/riccardo/jme3-bullet-native/jme3-bullet-native/$SUB_VERSION/$target_dir/jme3-bullet-native/$SUB_VERSION/jme3-bullet-native-$SUB_VERSION.jar?publish=1&override=1"
            fi

        done     

    fi

}

clr_magenta "Run with args ${*:1}..."
main ${*:1}
clr_magenta "Build complete, results are stored in $PWD/build/"


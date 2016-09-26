#!/bin/bash
# Author: Riccardo Balbo
# License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

# Configurations
if [ "$GITHUB_USERNAME" == "" ];
then
    GITHUB_USERNAME="riccardobl"
fi
if [ "$GROUP" == "" ];
then
    GROUP="org.jmonkeyengine.bullet_builder"
fi
if [ "$BRANCH" == "" ];
then
    BRANCH="master"
fi
if [ "$VERSION" == "" ];
then
    VERSION="1.0"
fi
if [ "$DEBUG" == "" ];
then
    DEBUG="0"
fi
###########################
###########################
# Init
REPO="https://github.com/$GITHUB_USERNAME/jmonkeyengine.git"
DEPLOY="false" 
JDK_ROOT="$JAVA_HOME"
READ_LINK="readlink"
if [ "`which greadlink`" != "" ]; 
then
    echo "Use greadlink"
    READ_LINK="greadlink"  
fi
JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/Commands/java::")"
if [ ! -f "$JDK_ROOT/Headers/jni.h" ];
then
    JDK_ROOT="$JAVA_HOME"
    if [ ! -f "$JDK_ROOT/include/jni.h" ];
    then
        JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/bin/java::")"
        if [ ! -f "$JDK_ROOT/include/jni.h" ];
        then
            JDK_ROOT="$($READ_LINK -f `which java` | sed "s:/jre/bin/java::")"
            if [ ! -f "$JDK_ROOT/include/jni.h" ];
            then
                echo "Can't find JDK"
            fi
        fi
    fi
fi
mkdir -p build
if [ ! -f "build/bash_colors.sh" ];
then
    wget  -q https://raw.githubusercontent.com/maxtsepkov/bash_colors/738f82882672babfaa21a2c5e78097d9d8118f91/bash_colors.sh -O build/bash_colors.sh
fi
source build/bash_colors.sh



###########################
###########################
#Download
function downloadIfRequired {
    if [ ! -d "build/bullet" ]; 
    then
        download
    fi
}
function download {
    clr_green "Download Bullet"
    rm -f build/tmp/vhacd.zip
    wget -q  https://github.com/bulletphysics/bullet3/archive/2.83.7.zip -O build/tmp/bullet.zip
    mkdir build/tmp/ext
    unzip -q build/tmp/bullet.zip -d  build/tmp/ext
    mv build/tmp/ext/* build/bullet
}




###########################
###########################
#Utils
function cleanTMP {
    rm -Rf build/tmp
    mkdir -p build/tmp
}
function clean {
    rm -R build
    mkdir build   
}
function setPlatformArch {
    PLATFORM=$1
    ARCH=$2
    OUT_PATH="$PWD/build/lib/native/$PLATFORM/$ARCH"
    mkdir -p $OUT_PATH
}
function findCppFiles { #Find .cpp and header paths that need to be passed to g++
    echo "">build/tmp/cpplist.txt
    find  build/bullet/src/BulletCollision -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/BulletDynamics -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/BulletInverseDynamics -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/BulletSoftBody -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/LinearMath -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/clew -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/tmp/jmonkeyengine/jme3-bullet-native/src/native/cpp/ -type f -name '*.cpp' >> build/tmp/cpplist.txt
    find  build/bullet/src/Bullet3Common -type f -name '*.cpp' >> build/tmp/cpplist.txt

    
    find  build/bullet/src/BulletCollision -type d  >> build/tmp/Ilist.txt
    find  build/bullet/src/BulletDynamics -type d  >> build/tmp/Ilist.txt
    find  build/bullet/src/BulletInverseDynamics -type d >> build/tmp/Ilist.txt
    find  build/bullet/src/BulletSoftBody -type d  >> build/tmp/Ilist.txt
    find  build/bullet/src/LinearMath -type d  >> build/tmp/Ilist.txt
    find  build/bullet/src/clew -type d  >> build/tmp/Ilist.txt
    find  build/bullet/src/Bullet3Common -type d  >> build/tmp/Ilist.txt

    for line in $(cat  build/tmp/Ilist.txt); do 
        echo "-I$line " >>  build/tmp/IIlist.txt
    done  
}



###########################
###########################
#Build scripts
function buildLinux {
    downloadIfRequired
    setPlatformArch "linux" $1
    clr_green "Compile for $PLATFORM $ARCH..."
    arch_flag="-m64"
    if [ "$1" = "x86" ];
    then
        arch_flag="-m32"
    fi
    findCppFiles

    args="-Ofast "
    if [ "$DEBUG" == "1" ];
    then
        args="-g -O1"
    fi

    build_script="
    g++ -mtune=generic -DBT_NO_PROFILE=1 -fpermissive -U_FORTIFY_SOURCE $args  -fPIC  $arch_flag -shared
      -Ibuild/bullet/src/
      -I$JDK_ROOT/include
      -I$JDK_ROOT/include/linux
      -Ibuild/tmp/jmonkeyengine/jme3-bullet-native/src/native/cpp
      $(cat  build/tmp/IIlist.txt) 
      $(cat build/tmp/cpplist.txt)
       -Wl,-soname,bulletjme.so -o $OUT_PATH/libbulletjme.so  -lrt"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}
function buildWindows {
    downloadIfRequired
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
       -Ibuild/bullet/src/
       -I$JDK_ROOT/include
       -Ibuild/tmp/win
       -Ibuild/tmp/jmonkeyengine/jme3-bullet-native/src/native/cpp  -static
       $(cat  build/tmp/IIlist.txt) 
      $(cat build/tmp/cpplist.txt) -Wp,-w 
       -Wl,--exclude-all-symbols,--add-stdcall-alias,--kill-at,-soname,bulletjme.dll  -o $OUT_PATH/bulletjme.dll"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}
function buildMac {
    downloadIfRequired
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
        -Ibuild/bullet/src/
      -Ibuild/tmp/jmonkeyengine/jme3-bullet-native/src/native/cpp 
            -I$JDK_ROOT/Headers/
      -I$JDK_ROOT/Headers/darwin
         $(cat  build/tmp/IIlist.txt) 
      $(cat build/tmp/cpplist.txt)
        -o $OUT_PATH/libbulletjme.dylib"
    clr_escape "$(echo $build_script)" $CLR_BOLD $CLR_BLUE
    $build_script
    if [ $? -ne 0 ]; then exit 1; fi
}



###########################
###########################
#Build Aliases
function buildWindows32 {
    buildWindows "x86"   
}
function buildWindows64 {
    buildWindows "x86_64"   
}
function buildMac32 {
    buildMac "x86"   
}
function buildMac64 {
    buildMac "x86_64"   
}
function buildLinux64 {
    buildLinux "x86_64"
}
function buildLinux32 {
    buildLinux "x86"
}
function buildAll {
    buildLinux32 
    buildLinux64  
    buildWindows32
    buildWindows64
}



###########################
###########################
#Travis
function travis {
    DEPLOY="false"

    VERSION=$TRAVIS_COMMIT
    if [ "$TRAVIS_TAG" != "" ];
    then
        echo "Deploy for $TRAVIS_TAG."
        VERSION=$TRAVIS_TAG #Set version to tag name
        DEPLOY="true"  #Deploy only on tags
    fi
    
    BINTRAY_VERSION="$VERSION"
   # BINTRAY_SNAPSHOT="$REPO_NAME-$BRANCH-SNAPSHOT"

    echo "Run travis $1"
    if [ "$1" = "deploy" ];
    then
        if [ "$DEPLOY" != "true" ];
        then
            exit 0
        fi  
          
        rm -Rf deploy
        mkdir -p deploy/
        
        # Check if windows and linux builds exist
        out=`curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent --head --write-out '%{http_code}'  -o deploy/tmpl.tar.gz.h  https://dl.bintray.com/riccardo/jme3-bullet-native-files/$BINTRAY_VERSION/libs-winLinux-$BINTRAY_VERSION.tar.gz`
        if [ "$out" != "200" ];
        then
            echo "[warning] Windows and Linux libs not found. Skip deploy."
            exit 0
        fi
        
        # Check if mac build exists
        out=`curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent --head --write-out '%{http_code}'  -o deploy/tmpm.tar.gz.h https://dl.bintray.com/riccardo/jme3-bullet-native-files/$BINTRAY_VERSION/libs-mac-$BINTRAY_VERSION.tar.gz`
        if [ "$out" != "200" ];
        then
            echo "[warning] Mac libs not found. Skip deploy."
            exit 0
        fi
        
        # Download linux & windows builds
        curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent  -o deploy/tmpl.tar.gz https://dl.bintray.com/riccardo/jme3-bullet-native-files/$BINTRAY_VERSION/libs-winLinux-$BINTRAY_VERSION.tar.gz   
       
       #Download mac build
        curl -u$BINTRAY_USER:$BINTRAY_API_KEY --silent  -o deploy/tmpm.tar.gz https://dl.bintray.com/riccardo/jme3-bullet-native-files/$BINTRAY_VERSION/libs-mac-$BINTRAY_VERSION.tar.gz
      

        # Build artifact
        echo "Deploy!"
        rm -Rf buid/tests/
        mkdir -p build/tests
        mkdir -p build/lib/        
        # Merge both builds together
        tar -xzf deploy/tmpl.tar.gz -C build/lib/ 
        tar -xzf deploy/tmpm.tar.gz -C build/lib/
        #Build jar 
        `which jar` cf deploy/jme3-bullet-native-$BINTRAY_VERSION.jar -C build/lib .
        #Upload on bintray
         target_dir=${GROUP//./\/}
         curl -X PUT  -T  deploy/jme3-bullet-native-$BINTRAY_VERSION.jar -u$BINTRAY_USER:$BINTRAY_API_KEY \
"https://api.bintray.com/content/riccardo/jme3-bullet-native/jme3-bullet-native/$BINTRAY_VERSION/$target_dir/jme3-bullet-native/$BINTRAY_VERSION/jme3-bullet-native-$BINTRAY_VERSION.jar?publish=1&override=1"
        #curl -X PUT  -T  deploy/jme3-bullet-native-$BINTRAY_VERSION.jar -u$BINTRAY_USER:$BINTRAY_API_KEY \
#"https://api.bintray.com/content/riccardo/jme3-bullet-native/jme3-bullet-native/$BINTRAY_SNAPSHOT/$target_dir/jme3-bullet-native/$BINTRAY_SNAPSHOT/jme3-bullet-native-$BINTRAY_SNAPSHOT.jar?publish=1&override=1"
                
    else
        if [ "$TRAVIS_OS_NAME" = "linux" ];
        then
            buildLinux32 
            buildLinux64  
            buildWindows32
            buildWindows64
            if [ "$DEPLOY" = "true" ];
            then           
                #Upload build to a temporary repository
                mkdir -p deploy/
                tar -C build/lib/ -czf deploy/libs-winLinux-$BINTRAY_VERSION.tar.gz .
                curl -X PUT  -T  deploy/libs-winLinux-$BINTRAY_VERSION.tar.gz -u$BINTRAY_USER:$BINTRAY_API_KEY\
                "https://api.bintray.com/content/riccardo/jme3-bullet-native-files/libs/$BINTRAY_VERSION/$BINTRAY_VERSION/"
           fi 
        fi
        if [ "$TRAVIS_OS_NAME" = "osx" ];
        then
            buildMac32
            buildMac64
            if [ "$DEPLOY" = "true" ];
            then    
                #Upload build to a temporary repository
                mkdir -p deploy/
                tar -C build/lib/ -czf deploy/libs-mac-$BINTRAY_VERSION.tar.gz .
                curl -X PUT  -T  deploy/libs-mac-$BINTRAY_VERSION.tar.gz -u$BINTRAY_USER:$BINTRAY_API_KEY\
                "https://api.bintray.com/content/riccardo/jme3-bullet-native-files/libs/$BINTRAY_VERSION/$BINTRAY_VERSION/"

            fi 
        fi
    fi
}



###########################
###########################
#Main
function main(){
 
    if [ "$1" = "" ];
    then
        echo "Usage: make.sh target"
        echo " - Targets: buildAll,buildWindows32,buildWindows64,buildLinux32,buildLinux64,buildMac32,buildMac64,clean"
        exit 0
    fi

    cleanTMP
    if [ ! -d "build/jmonkeyengine" ]; then
        clr_green "Clone engine $REPO:$BRANCH..."
        git clone $REPO build/jmonkeyengine
        cd build/jmonkeyengine
        git checkout $BRANCH
        cd ../../
    fi
    mkdir -p build/tmp/win
    wget https://raw.githubusercontent.com/riccardobl/jme3-bullet-builder/root/win/jni_md.h -O build/tmp/win/jni_md.h
    wget https://raw.githubusercontent.com/riccardobl/jme3-bullet-builder/root/win/jawt_md.h -O build/tmp/win/jawt_md.h

    cp -Rf build/jmonkeyengine build/tmp/jmonkeyengine 

    clr_magenta "Run $1..."
    $1 ${*:2}
    clr_magenta "Build complete, results are stored in $PWD/build/"
}


#Start script
#main $@

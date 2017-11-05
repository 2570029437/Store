#!/bin/bash

FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.zip
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"

echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc

echo -e "Download smlib"
mkdir smlib
wget "https://codeload.github.com/bcserv/smlib/zip/master" -q -O smlib.zip
unzip -qo smlib.zip -d smlib/
mv smlib/smlib-master/scripting/include/* include

echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp

echo -e "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done

echo -e "Check addons/sourcemod/scripting/store ..."
if [ ! -d "addons/sourcemod/scripting/store" ]; then
  mkdir addons/sourcemod/scripting/store
fi

echo -e "Check addons/sourcemod/scripting/store/modules ..."
if [ ! -d "addons/sourcemod/scripting/store/modules" ]; then
  mkdir addons/sourcemod/scripting/store/modules
fi

echo -e "Copy scripts to compiler folder ..."
cp -r store/* addons/sourcemod/scripting/store
cp -r include/* addons/sourcemod/scripting/include

echo -e "Check build folder"
mkdir build
mkdir build/plugins
mkdir build/plugins/sp
mkdir build/plugins/smx
mkdir build/plugins/modules
mkdir build/plugins/modules/sp
mkdir build/plugins/modules/smx
mkdir build/models
mkdir build/materials
mkdir build/particles
mkdir build/sound

echo -e "Compiling store [ttt] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[ttt] failed!"
    exit 1;
fi

mkdir build/plugins/sp/ttt
mkdir build/plugins/smx/ttt
mv addons/sourcemod/scripting/store.sp build/plugins/sp/ttt
mv store.smx build/plugins/smx/ttt

echo -e "Compiling store [ze] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[ze] failed!"
    exit 1;
fi

mkdir build/plugins/sp/ze
mkdir build/plugins/smx/ze
mv addons/sourcemod/scripting/store.sp build/plugins/sp/ze
mv store.smx build/plugins/smx/ze

echo -e "Compiling store [mg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[mg] failed!"
    exit 1;
fi

mkdir build/plugins/sp/mg
mkdir build/plugins/smx/mg
mv addons/sourcemod/scripting/store.sp build/plugins/sp/mg
mv store.smx build/plugins/smx/mg

echo -e "Compiling store [jb] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[jb] failed!"
    exit 1;
fi

mkdir build/plugins/sp/jb
mkdir build/plugins/smx/jb
mv addons/sourcemod/scripting/store.sp build/plugins/sp/jb
mv store.smx build/plugins/smx/jb

echo -e "Compiling store [kz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[kz] failed!"
    exit 1;
fi

mkdir build/plugins/sp/kz
mkdir build/plugins/smx/kz
mv addons/sourcemod/scripting/store.sp build/plugins/sp/kz
mv store.smx build/plugins/smx/kz

echo -e "Compiling store module[pet] ..."
cp modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp

if [ ! -f "store_pet.smx" ]; then
    echo "Compile store module[pet] failed!"
    exit 1;
fi

mv addons/sourcemod/scripting/store_pet.sp build/plugins/modules/sp
mv store_pet.smx build/plugins/modules/smx

echo -e "Compiling fpvmi ..."
cp fpvm_interface.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/fpvm_interface.sp

if [ ! -f "fpvm_interface.smx" ]; then
    echo "Compile fpvm_interface failed!"
    exit 1;
fi

mv fpvm_interface.smx build/plugins

echo -e "Compiling chat-processor ..."
cp chat-processor.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/chat-processor.sp

if [ ! -f "chat-processor.smx" ]; then
    echo "Compile chat-processor failed!"
    exit 1;
fi

mv chat-processor.smx build/plugins

echo -e "Prepare file ..."
cd resources
7za -e ./materials/materials.7z
7za -e ./models/models.7z
7za -e ./particles/particles.7z
7za -e ./sound/sound.7z
mv -rf ./materials/* build/materials
mv -rf ./models/* build/models
mv -rf ./particles/* build/particles
mv -rf ./sound/* build/sound

echo -e "Compress file ..."
cd ../build
zip -9rq $FILE LICENSE plugins models materials particles sound


echo -e "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O Store/$5/$1/ $FILE"
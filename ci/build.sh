#!/bin/bash

#参数
FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.7z
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"


#INFO
echo -e "*** Trigger build ***"


#下载SM
echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#下载CG头文件
echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc


#下载FPVMI头文件
echo -e "Download fpvm_interface.inc ..."
#wget "https://github.com/Franc1sco/First-Person-View-Models-Interface/raw/master/scripting/include/fpvm_interface.inc" -q -O include/fpvm_interface.inc
wget "https://github.com/Kxnrl/First-Person-View-Models-Interface/raw/master/scripting/include/fpvm_interface.inc" -q -O include/fpvm_interface.inc


#下载Chat-Processor头文件
echo -e "Download cg_core.inc ..."
wget "https://github.com/Drixevel/Chat-Processor/raw/master/scripting/include/chat-processor.inc" -q -O include/chat-processor.inc


#设置文件为可执行
echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo -e "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done


#建立文件夹以准备拷贝文件
mkdir addons/sourcemod/scripting/store
mkdir addons/sourcemod/scripting/store/modules


#拷贝文件到编译器文件夹
echo -e "Copy scripts to compiler folder ..."
cp -rf store/* addons/sourcemod/scripting/store
cp -rf include/* addons/sourcemod/scripting/include


#建立输出文件夹
echo -e "Check build folder ..."
mkdir build
mkdir build/addons
mkdir build/addons/sourcemod/
mkdir build/addons/sourcemod/configs
mkdir build/addons/sourcemod/plugins
mkdir build/addons/sourcemod/plugins/modules
mkdir build/addons/sourcemod/plugins_CG
mkdir build/addons/sourcemod/plugins_CG/modules
mkdir build/addons/sourcemod/scripting
mkdir build/addons/sourcemod/scripting/modules
mkdir build/addons/sourcemod/scripting_CG
mkdir build/addons/sourcemod/scripting_CG/modules
mkdir build/addons/sourcemod/translations
mkdir build/models
mkdir build/materials
mkdir build/particles
mkdir build/sound


#编译Store主程序 => TTT
#编译CG版本
echo -e "Compiling store core [ttt] *CG* ..."
cp -f store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins_CG/store_tt.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins_CG/store_tt.smx" ]; then
    echo "Compile store core [ttt] *CG* failed!"
    exit 1;
fi
cp -f addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting_CG
mv build/addons/sourcemod/scripting_CG/store.sp build/addons/sourcemod/scripting_CG/store_tt.sp
#编译通用版本
echo -e "Compiling store core [ttt] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_tt.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_tt.smx" ]; then
    echo "Compile store core [ttt] *Global* failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_tt.sp


#编译Store主程序 => ZE
#编译CG版本
echo -e "Compiling store core [ze] *CG* ..."
cp -f store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins_CG/store_ze.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins_CG/store_ze.smx" ]; then
    echo "Compile store core [ze] *CG* failed!"
    exit 1;
fi
cp -f addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting_CG
mv build/addons/sourcemod/scripting_CG/store.sp build/addons/sourcemod/scripting_CG/store_ze.sp
#编译通用版本
echo -e "Compiling store core [ze] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_ze.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_ze.smx" ]; then
    echo "Compile store core [ze] *Global* failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_ze.sp


#编译Store主程序 => MG
#编译CG版本
echo -e "Compiling store core [mg] *CG* ..."
cp -f store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins_CG/store_mg.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins_CG/store_mg.smx" ]; then
    echo "Compile store core [mg] *CG* failed!"
    exit 1;
fi
cp -f addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting_CG
mv build/addons/sourcemod/scripting_CG/store.sp build/addons/sourcemod/scripting_CG/store_mg.sp
#编译通用版本
echo -e "Compiling store core [mg] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_mg.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_mg.smx" ]; then
    echo "Compile store core [mg] *Global* failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_mg.sp


#编译Store主程序 => JB
#编译CG版本
echo -e "Compiling store core [jb] *CG* ..."
cp -f store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins_CG/store_jb.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins_CG/store_jb.smx" ]; then
    echo "Compile store core [jb] *CG* failed!"
    exit 1;
fi
cp -f addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting_CG
mv build/addons/sourcemod/scripting_CG/store.sp build/addons/sourcemod/scripting_CG/store_jb.sp
#编译通用版本
echo -e "Compiling store core [jb] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_jb.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_jb.smx" ]; then
    echo "Compile store core [jb] *Global* failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_jb.sp


#编译Store主程序 => KZ
#编译CG版本
echo -e "Compiling store core [kz] *CG* ..."
cp -f store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins_CG/store_kz.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins_CG/store_kz.smx" ]; then
    echo "Compile store core [kz] *CG* failed!"
    exit 1;
fi
cp -f addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting_CG
mv build/addons/sourcemod/scripting_CG/store.sp build/addons/sourcemod/scripting_CG/store_kz.sp
#编译通用版本
echo -e "Compiling store core [kz] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_kz.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_kz.smx" ]; then
    echo "Compile store core [kz] *Global* failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_kz.sp


#编译Store模组Pets
echo -e "Compiling store module [pet] ..."
cp -f modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp >nul
if [ ! -f "store_pet.smx" ]; then
    echo "Compile store module[pet] failed!"
    exit 1;
fi
cp addons/sourcemod/scripting/store_pet.sp build/addons/sourcemod/scripting_CG/modules
cp store_pet.smx build/addons/sourcemod/plugins_CG/modules
mv addons/sourcemod/scripting/store_pet.sp build/addons/sourcemod/scripting/modules
mv store_pet.smx build/addons/sourcemod/plugins/modules


#解压素材文件
echo -e "Extract resource file ..."
echo -e "Processing archive: resources/materials/materials.7z"
7z x "resources/materials/materials.7z" -o"build/materials" >nul
mv resources/materials/materials.txt build/materials
echo -e "Processing archive: resources/materials/models.7z"
7z x "resources/models/models.7z" -o"build/models" >nul
mv resources/models/models.txt build/models
echo -e "Processing archive: resources/materials/particles.7z"
7z x "resources/particles/particles.7z" -o"build/particles" >nul
mv resources/particles/particles.txt build/particles
echo -e "Processing archive: resources/materials/sound.7z"
7z x "resources/sound/sound.7z" -o"build/sound" >nul
mv resources/sound/sound.txt build/sound


#移动配置和翻译文件
echo -e "Move configs and translations to build folder ..."
mv configs/* build/addons/sourcemod/configs
mv translations/* build/addons/sourcemod/translations
mv utils build
mv LICENSE build
mv README.md build


#移动其他的代码文件
echo -e "Move other scripts to build folder ..."
cp -rf store build/addons/sourcemod/scripting_CG
cp -rf include build/addons/sourcemod/scripting_CG
mv -f store build/addons/sourcemod/scripting
mv -f include build/addons/sourcemod/scripting


#打包
echo -e "Compress file ..."
cd build
if [ "$5" = "master" ]; then
    7z a $FILE -t7z -mx9 LICENSE README.md addons utils materials models particles sound >nul
else
    7z a $FILE -t7z -mx9 LICENSE README.md addons utils >nul
fi


#上传
echo -e "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/$5/$1/ $FILE"


#RAW
if [ "$1" = "1.8" ] && [ "$5" = "master" ]; then
    echo "Upload RAW..."
    cd addons/sourcemod/plugins_CG
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_tt.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_ze.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_mg.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_jb.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_kz.smx"
fi
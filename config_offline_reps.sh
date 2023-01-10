#!/usr/bin/env bash

REGEXP_TGZ=".*\.tgz"
REGEXP_ISO=".*\.iso"


RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

declare -a TGZ_LIST
declare -a ISO_LIST

while [ -n "$1" ]
do
    if [ -f $1 ]
    then
        if [[ $1 =~ $REGEXP_TGZ ]]
        then 
            TGZ_LIST+=($1)
        elif [[ $1 =~ $REGEXP_ISO ]]
        then
            ISO_LIST+=($1)
        else
            echo -e ${YELLOW}"Расширение файла $1 не соответствует ожидаемому (tgz или iso). Он не будет обработан${NC}"
        fi
    else
        echo -e ${YELLOW}"Файл $1 не существует${NC}"
    fi
    shift
done

for i in ${ISO_LIST[@]}
do 
    FILE=$(sed 's/\(.*\)\.iso$/\1/g' <<< $i)
    mkdir /mnt/$FILE
    mount $(pwd)/$i /media/cdrom
	  echo -e ${GREEN}"Копирование файлов из образа $i в /mnt/$FILE ${NC}"
    cp -r /media/cdrom/* /mnt/$FILE
    umount /media/cdrom
    echo 'deb file:/mnt/'$FILE' 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list
    
    IS_BOOT_DISK=$(find /mnt/$FILE -name "boot")
    if [ -n "$IS_BOOT_DISK" ]
    then
        
        echo -e ${YELLOW}"Обнаружено, что образ $i является загрузочным. В файле /etc/apt/source.list будет закомментирована строка, указывающая что его необходимо искать во вставленных дисках. Вместо этого он будет хранитсья на диске в каталоге /mnt${NC}"
        
        $(sed -i 's/\(^deb.*OS Astra Linux .*\)/#\1/g' /etc/apt/sources.list)
    fi
    
done

for i in ${TGZ_LIST[@]}
do 
    FILE=$(sed 's/\(.*\)\.tgz$/\1/g' <<< $i)
    mkdir /mnt/$FILE
    echo -e ${GREEN}"Распаковка архива $i в /mnt/$FILE ${NC}"
    $(tar xzvf $(pwd)/$i -C /mnt/$FILE)
    PATH_TO_DISTS=$(find /mnt/$FILE -name 'dists')
    FOLDER_WITH_DISTS=$(sed 's/\(.*\)\/.*/\1/g' <<< $PATH_TO_DISTS)
    echo 'deb file:'$FOLDER_WITH_DISTS' 1.7_x86-64 main contrib non-free' >> /etc/apt/sources.list
done

apt update

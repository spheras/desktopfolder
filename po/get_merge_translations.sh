#!/bin/sh
tx pull -a -f --minimum-perc=46

cd po
rm LINGUAS

for i in *.po ; do
    echo `echo $i|sed 's/.po$//'` >> LINGUAS
done

sed -i 's/CHARSET/UTF-8/g' *.po

intltool-merge --desktop-style . ../data/com.github.spheras.desktopfolder.desktop.in ../data/com.github.spheras.desktopfolder.desktop

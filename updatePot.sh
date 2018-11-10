#!/bin/bash

function do_gettext()
{
    xgettext --package-name=com.github.spheras.desktopfolder --package-version=1.0.10 $* --default-domain=desktopfolder --join-existing --from-code=UTF-8
}

function do_intltool()
{
    intltool-extract --type=$1 $2
}

rm desktopfolder.po -f
touch desktopfolder.po

for file in `find . -name "*.py" -or -name "*.vala"`; do
    if [[ `grep -F "_(\"" $file` ]]; then
        do_gettext $file --add-comments
    fi
done

#for file in `find src -name "*.ui"`; do
#    if [[ `grep -F "translatable=\"yes\"" $file` ]]; then
#        do_intltool gettext/glade $file
#        do_gettext ${file}.h --add-comments --keyword=N_:1
#        rm $file.h
#    fi
#done

for file in `find . -name "*.in"`; do
    if [[ `grep -E "^_*" $file` ]]; then
        do_intltool gettext/keys $file
        do_gettext ${file}.h --add-comments --keyword=N_:1
        rm $file.h
    fi
done

mv desktopfolder.po po/com.github.spheras.desktopfolder.pot

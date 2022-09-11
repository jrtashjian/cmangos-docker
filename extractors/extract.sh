#!/bin/bash

PATH_TO_CLIENT=/client
PATH_TO_EXTRACTORS=/opt/cmangos/bin/tools

cd $PATH_TO_EXTRACTORS
files_to_cleanup="$(ls *)"
cp $PATH_TO_EXTRACTORS/* $PATH_TO_CLIENT/

cd $PATH_TO_CLIENT/
bash ./ExtractResources.sh

mv $PATH_TO_CLIENT/Cameras /maps
mv $PATH_TO_CLIENT/dbc /maps
mv $PATH_TO_CLIENT/maps /maps
mv $PATH_TO_CLIENT/mmaps /maps
mv $PATH_TO_CLIENT/vmaps /maps

# Cleanup client directory
rm -vf $PATH_TO_CLIENT/MaNGOSExtractor.log
rm -vf $PATH_TO_CLIENT/MaNGOSExtractor_detailed.log
rm -vrf $PATH_TO_CLIENT/Buildings

for filepath in "${files_to_cleanup[@]}"
do
	rm -vf $filepath
done
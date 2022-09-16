#!/bin/bash

PATH_TO_CLIENT=/client
PATH_TO_OUTPUT=/maps
PATH_TO_EXTRACTORS=/opt/cmangos/bin/tools

echo "$(date): Start extraction of DBCs and map files..."
$PATH_TO_EXTRACTORS/ad -f 0 -i $PATH_TO_CLIENT -o $PATH_TO_OUTPUT

echo "$(date): Start extraction of vmaps..."
$PATH_TO_EXTRACTORS/vmap_extractor -l -d $PATH_TO_CLIENT/Data -o $PATH_TO_OUTPUT

echo "$(date): Start assembling of vmaps..."
mkdir $PATH_TO_OUTPUT/vmaps
$PATH_TO_EXTRACTORS/vmap_assembler $PATH_TO_OUTPUT/Buildings $PATH_TO_OUTPUT/vmaps

echo "$(date): Start extraction of mmaps..."
mkdir $PATH_TO_OUTPUT/mmaps
$PATH_TO_EXTRACTORS/MoveMapGen --offMeshInput $PATH_TO_EXTRACTORS/offmesh.txt --workdir $PATH_TO_OUTPUT

exit 0
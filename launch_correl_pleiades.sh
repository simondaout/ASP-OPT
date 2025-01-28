#!/usr/bin/bash

# load asp
module load asp

# help
Help()
{
   # Display Help
   echo "Syntax: launch_correl_pleiades.sh asp_parameters.txt"
   echo "asp_parameters.txt: parameter file"
   echo
}

if [ -z $1 ]; then { Help; exit 1; } fi
source $1

if [ ${#DATES1[@]} -ne ${#DATES2[@]} ] || [ ${#DATES1[@]} -ne ${#GEOMS[@]} ]; then
    echo "DATES1 DATES2 GEOMS not the same size"
    exit 1
fi

for ((i=0; i<${#DATES1[@]}; i++)); do

DATE1=${DATES1[i]} 
DATE2=${DATES2[i]}
GEOM=${GEOMS[i]}

IMG1="$HOME/INPUT/orthoimage_"$GEOM"_"$DATE1".tif"
IMG2="$HOME/INPUT/orthoimage_"$GEOM"_"$DATE2".tif"
IMG1_CROP="$HOME/INPUT/orthoimage_"$GEOM"_crop_"$DATE1".tif"
IMG2_CROP="$HOME/INPUT/orthoimage_"$GEOM"_crop_"$DATE2".tif"

#####################
# CROP
#####################

CROP1=`echo ${CROP[0]}`
CROP2=`echo ${CROP[1]}`
CROP3=`echo ${CROP[2]}`
CROP4=`echo ${CROP[3]}`

echo $CROP1 $CROP2 $CROP3 $CROP4
gdal_translate -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff $IMG1 $IMG1_CROP 
gdal_translate -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff $IMG2 $IMG2_CROP  

#####################
# CORRELATION
#####################

cd $HOME
DIR1=${DATE1:0:8}
DIR2=${DATE2:0:8}
PAIR=$DIR1"_"$DIR2
mkdir $PAIR
cd $PAIR

if [ -z "$FILTER_MODE" ]; then
    FILTER_MODE="2"
fi
if [ -z "$RM_QUANT_PC" ]; then
    RM_QUANT_PC="0.85"
fi
if [ -z "$RM_MIN_MATCHES" ]; then
    RM_MIN_MATCHES="60"
fi
if [ -z "$RM_THRESHOLD" ]; then
    RM_THRESHOLD="3"
fi

session=" -t $SESSION_TYPE --correlator-mode --individually-normalize --alignment-method $A_M --threads-multiprocess $THREADS --process $THREADS --no-bigtiff --tif-compress Deflate"
stereo="--corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE "
denoising="--rm-quantile-multiple $RM_QUANT_MULT --filter-mode $FILTER_MODE --rm-quantile-percentile $RM_QUANT_PC --rm-min-matches $RM_MIN_MATCHES --rm-threshold $RM_THRESHOLD" 
filtering="--median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE"

parallel_stereo $session $IMG1_CROP $IMG2_CROP $BLACK_LEFT $BLACK_RIGHT $OUTPUT_DIR $stereo $filtering  
gdal_translate -q -b 1 -co COMPRESS=LZW $OUTPUT_DIR-F.tif WE_"$GEOM"_"$DIR1"_"$DIR2"_filter.tif
gdal_translate -q -b 2 -co COMPRESS=LZW $OUTPUT_DIR-F.tif NS_"$GEOM"_"$DIR1"_"$DIR2"_filter.tif
gdal_translate -q -b 3  $OUTPUT_DIR-F.tif CC_"$GEOM"_"$DIR1"_"$DIR2"_filter.tif

done

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

if [ ${#DATES1[@]} -ne ${#DATES2[@]} ] || [ ${#DATES1[@]} -ne ${#BANDS[@]} ]; then
    echo "DATES1 DATES2 BANDS not the same size"
    exit 1
fi

for ((i=0; i<${#DATES1[@]}; i++)); do

DATE1=${DATES1[i]} 
DATE2=${DATES2[i]}
BAND=${BANDS[i]}

IMG1="$HOME/data/T11SMV_"$DATE1"_"$BAND".jp2"
IMG2="$HOME/data/T11SMV_"$DATE2"_"$BAND".jp2"
IMG1_CROP="$HOME/data/T11SMV_"$DATE1"_"$BAND"_crop.tiff"
IMG2_CROP="$HOME/data/T11SMV_"$DATE2"_"$BAND"_crop.tiff"

#gdal_translate -of GTiff $IMG1 $IMG1_CROP
#gdal_translate -of GTiff $IMG2 $IMG2_CROP

#####################
# CORRELATION
#####################

cd $HOME
DIR1=${DATE1:0:8}
DIR2=${DATE2:0:8}
#PAIR=$DIR1"_"$DIR2
mkdir $OUTPUT_DIR
cd $OUTPUT_DIR

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

session=" -t $SESSION_TYPE --individually-normalize --alignment-method $A_M --threads-multiprocess $THREADS --process $THREADS --no-bigtiff --tif-compress Deflate "
stereo="--corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --corr-sub-seed-percent $CORR_S_MODE_PERC --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE "
denoising="--rm-quantile-multiple $RM_QUANT_MULT --filter-mode $FILTER_MODE --rm-quantile-percentile $RM_QUANT_PC --rm-min-matches $RM_MIN_MATCHES --rm-threshold $RM_THRESHOLD" 
filtering="--median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE"

parallel_stereo $session $IMG1 $IMG2 $BLACK_LEFT $BLACK_RIGHT $OUTPUT_DIR $stereo $denoising $filtering  
gdal_translate -q -b 1 -co COMPRESS=LZW $OUTPUT_DIR-F.tif WE_"$BAND"_"$DIR1"_"$DIR2"_filter.tif
gdal_translate -q -b 2 -co COMPRESS=LZW $OUTPUT_DIR-F.tif NS_"$BAND"_"$DIR1"_"$DIR2"_filter.tif
gdal_translate -q -b 3  $OUTPUT_DIR-F.tif CC_"$BAND"_"$DIR1"_"$DIR2"_filter.tif

done

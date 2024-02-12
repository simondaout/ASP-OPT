#! /bin/bash

INPUT=$1
OUTPUT=$2
type=$3

# Initial checkings
if [ "$INPUT" = "" ]; then
  echo "usage : prep_data.sh path_to_input_dir path_to_output_data type_data (e.g. LC08 or SENT)"
  echo "create "
  echo ; exit
fi

#Suppress all tmp files
trap 'rm -f *.tmp$$ err.$$ ; exit' 0 1 2 3 15

# List source data
ls $INPUT > $INPUT/1.tmp$$

# Source File
INFILE=`cat $INPUT/1.tmp$$ | grep $type`

# checkings
if [ "$INFILE" = "" ]; then
  echo "no source data"
  echo ; exit
fi

echo "Remove text file images.txt ?"
rm images.txt

for DATA in $INFILE; do
	ROOTNAME="${DATA%.*}"
	SUFFIX="${DATA##*.}"
	mkdir $OUTPUT/$ROOTNAME
	if [ "$SUFFIX" = "gz" ]; then
		tar zxvf $INPUT/$DATA -C $OUTPUT/$ROOTNAME
	elif [ "$SUFFIX" = "zip" ]; then
		# sentinel zip files comes into a .SAFE folder
		unzip $INPUT/$DATA -d $OUTPUT/.
	else
		echo "not recognized compress file"
	fi
	rm -f $OUTPUT/$ROOTNAME/*B1* $OUTPUT/$ROOTNAME/*B2* $OUTPUT/$ROOTNAME/*B1* $OUTPUT/$ROOTNAME/*B3* $OUTPUT/$ROOTNAME/*B4* $OUTPUT/$ROOTNAME/*B5* $OUTPUT/$ROOTNAME/*B6* $OUTPUT/$ROOTNAME/*B7* $OUTPUT/$ROOTNAME/*B9* $OUTPUT/$ROOTNAME/*B10*
	echo $OUTPUT/$ROOTNAME >> images.txt
done	 

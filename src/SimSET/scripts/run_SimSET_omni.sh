#! /bin/bash
#PBS -k eo 
# better to add this in the qsub statement PBS -l vmem=1900mb

# Script to run simset simulations
# Authors: Pablo Aguiar, Kris Thielemans, Nikos Dikaios

# Still relies on a few things such as
# - scanner is hardwired via template files
# WARNING
# scanner z-coordinates in the templates have to fit with STIR conventions:
# z=0 corresponds to the centre of the first slice of the image
#
# You need to set various environment variables to run this script.
# Check the code below and the example.
#
#  Copyright (C) 2005 - 2006, Hammersmith Imanet Ltd
#  Copyright (C) 2011-07-01 - 2012, Kris Thielemans
#  This file is part of STIR.
#
#  SPDX-License-Identifier: Apache-2.0
#
#  See STIR/LICENSE.txt for details
#      

script_name=$0

####################### Script inputs ##################################

# These directories have to be changed for differents users
SIMSET_DIR=/home/treeves/2.9.2

if [ $# -ne 0 -o -z "${SIMSET_DIR}" ]; then
    echo Environment variable SIMSET_DIR needs to be set
    exit 1
fi


if [ $# -ne 0 -o -z "${DIR_INPUT}" ]; then
    echo Environment variable DIR_INPUT will default to current directory.
    DIR_INPUT=`pwd`
fi

if [ $# -ne 0 -o -z "${DIR_OUTPUT}" ]; then
    if [ $# -ne 0 -o -z "${SIM_NAME}" ]; then
      echo "usage: $0 "
      echo environment variable SIM_NAME or DIR_OUTPUT has to be defined
      exit 1
    fi
    DIR_OUTPUT=${DIR_INPUT}/${SIM_NAME}
fi
echo Output data will be in ${DIR_OUTPUT}


if [ $# -ne 0 -o -z "${PHOTONS}" ]; then
    echo "usage: $0 "
    echo environment variable PHOTONS has to be defined
    echo Contains the number of decays to run
    exit 1
fi

if [ $# -ne 0 -o -z "${EMISS_DATA}" ]; then
    echo "usage: $0 "
    echo environment variable EMISS_DATA has to be defined
    echo Emission Data Filename
    exit 1
fi


if [ $# -ne 0 -o -z "${ATTEN_DATA}" ]; then
    echo "usage: $0 "
    echo environment variable ATTEN_DATA has to be defined
    echo "Attenuation Data Filename (in mu-values units cm^-1)"
    exit 1
fi

if [ $# -ne 0 -o -z "${SCANNER}" ]; then
    echo "usage: $0 "
    echo environment variable SCANNER has to be defined
    echo Has to be set to a scanner name that STIR understands if you want all dimensions to be ok.
    exit 1
fi

num_seg=0
if [ ! -z "${NUM_SEG}" ]; then
num_seg=${NUM_SEG}
fi

convert_att_to_simset=1
if [ ! -z "${CONVERT_ATT_TO_SIMSET}" ]; then
convert_att_to_simset=${CONVERT_ATT_TO_SIMSET}
fi

echo "convert_att_to_simset=$convert_att_to_simset"

if [ $# -ne 0 -o -z "${TEMPLATE_PHG}" ]; then
    TEMPLATE_PHG=phg_with_tomos.rec
fi
echo "Using ${TEMPLATE_PHG}"

if [ $# -ne 0 -o -z "${TEMPLATE_BIN}" ]; then
    TEMPLATE_BIN=template_bin_omni.rec
fi
echo "Using ${TEMPLATE_BIN}"

if [ $# -ne 0 -o -z "${TEMPLATE_DET}" ]; then
    TEMPLATE_DET=template_det.rec
fi
echo "Using ${TEMPLATE_DET}"

########################  Script code ###################################
# function to parse simset file
# Usage:
#   find_param params_file param
# outputs value of parameter
find_param()
{
 # get all occurences and sort numerically
 grep "[[:blank:]]$2" $1|uniq|awk -F= '{print $2}'|sort -g
}

# exit on error
# trap 'echo "ERROR in script $script_name on line $LINENO: command \`$BASH_COMMAND\` failed"' ERR

echo "Preparing files for SimSET from templates and images"

mkdir -p ${DIR_OUTPUT}

cd ${DIR_INPUT}

######## Creating Simset input files

# Copying into DIR_OUTPUT what SimSET needs to run
if [ ${DIR_INPUT} != ${DIR_OUTPUT} -o ${TEMPLATE_DET} != det.rec ]; then
  cp ${TEMPLATE_DET} ${DIR_OUTPUT}/det.rec
fi

if ! cd "${DIR_OUTPUT}"; then
    echo "ERROR: Failed to cd into DIR_OUTPUT=${DIR_OUTPUT}" >&2
    exit 1
fi
# first convert input emission to 1byte data
cat > output_format_1byte.par  <<EOF
output file format parameters:=
output file format type:=interfile
Interfile Output File Format Parameters:=
number format:=signed integer
number_of_bytes_per_pixel:=1
end Interfile Output File Format Parameters:=
end :=
EOF
stir_math  --output-format output_format_1byte.par \
   act.dat ${EMISS_DATA}
rm -f output_format_1byte.par

if [ $convert_att_to_simset == 1 ]; then
  # convert attenuation image to simset indices
  conv_to_SimSET_att_image att.dat ${ATTEN_DATA}
else
  cp ${ATTEN_DATA} att.dat
fi


# Building bin.rec and phg.rec from templates
sed -e s#SIMSET_DIRECTORY#${SIMSET_DIR}# \
    -e s#INPUT_DIRECTORY#${DIR_INPUT}# \
    -e s#OUTPUT_DIRECTORY#${DIR_OUTPUT}# \
    -e s#BIN.REC#bin.rec# \
    -e s#DET.REC#det.rec# \
    -e s#PHOTONS#${PHOTONS}# \
  < ${TEMPLATE_PHG} > phg.rec
#-e s#BIN.REC#bin.rec# \

sed -e s#SIMSET_DIRECTORY#${SIMSET_DIR}# \
    -e s#INPUT_DIRECTORY#${DIR_INPUT}# \
    -e s#OUTPUT_DIRECTORY#${DIR_OUTPUT}# \
  < "${DIR_INPUT}/${TEMPLATE_BIN}" > bin.rec


#sed -e s#SIMSET_DIRECTORY#${SIMSET_DIR}# \
#    -e s#INPUT_DIRECTORY#${DIR_INPUT}# \
#    -e s#OUTPUT_DIRECTORY#${DIR_OUTPUT}# \
#  < ${TEMPLATE_BIN_2} > bin_2.rec

# add object geometric def
stir_image_to_simset_object.sh ${EMISS_DATA} >> phg.rec

# Building index.dat to input in makeindexfile
echo phg.rec > index.dat
echo y >> index.dat
echo y >> index.dat
echo 0 >> index.dat
echo y >> index.dat
echo act.dat >> index.dat
echo 0 >> index.dat
echo 0 >> index.dat
echo 1 >> index.dat
echo n >> index.dat
echo n >> index.dat
echo y >> index.dat
echo y >> index.dat
echo 0 >> index.dat
echo y >> index.dat
echo att.dat >> index.dat
echo 0 >> index.dat
echo 0 >> index.dat
echo 1 >> index.dat
echo n >> index.dat
echo n >> index.dat

$SIMSET_DIR/bin/makeindexfile < index.dat > ${DIR_OUTPUT}/makeindex.log 2>&1

echo "DIR_OUTPUT = ${DIR_OUTPUT}"


######### Run SimSET

echo "Starting phg (log in ${DIR_OUTPUT}/phg.log) ..."
#ls -l "${DIR_OUTPUT}/phg.rec" >&2
$SIMSET_DIR/bin/phg ${DIR_OUTPUT}/phg.rec > ${DIR_OUTPUT}/phg.log 2>&1
echo "... phg done. "


#rm -f ${DIR_OUTPUT}/rec.stat ${DIR_OUTPUT}/*.weight2 ${DIR_OUTPUT}/*.count ${DIR_OUTPUT}/index.dat
# gzip ${DIR_OUTPUT}/*weight*
#rm ${DIR_OUTPUT}/rec.act_indexes ${DIR_OUTPUT}/rec.activity_image ${DIR_OUTPUT}/rec.att_indexes ${DIR_OUTPUT}/rec.attenuation_image

########## Convert output files

log=${DIR_OUTPUT}/convert_SimSET_STIR.log
echo "Starting conversion to STIR format (log in ${log}) ..."

# find output filenames
#weight_filename=`find_param bin.rec weight_image_path|tr -d \"`
activity_image=`find_param phg.rec activity_image|tr -d \"`
attenuation_image=`find_param phg.rec attenuation_image|tr -d \"`

# convert
rm -f ${log}


bin_file=${DIR_INPUT}/template_bin_omni.rec
#scatter_parameter=$(find_param "$bin_file" scatter_param | tr -d '"' | xargs)
#weight_filename=${DIR_OUTPUT}/rec_min_omni.weight
#conv_SimSET_projdata_to_STIR_energy_windows.sh "$weight_filename" "$num_seg" "$SCANNER" "$i" "$scatter_parameter" >> "$log" 2>&1


# For different energy windows
#for (( i=360; i<=520; i+=20 )); do
#  bin_file=${DIR_INPUT}/bin_min${i}_crystal.rec
#    scatter_parameter=$(find_param "$bin_file" scatter_param | tr -d '"' | xargs)
#  weight_filename=${DIR_OUTPUT}/rec_min${i}.weight
#  conv_SimSET_projdata_to_STIR_energy_windows.sh "$weight_filename" "$num_seg" "$SCANNER" "$i" "$scatter_parameter" >> "$log" 2>&1
#done


if [ ! -z "${activity_image}" ]; then
  make_hv_from_Simset_params.sh phg.rec ${activity_image} 2>&1 >> ${log}
fi
if [ ! -z "${attenuation_image}" ]; then
  make_hv_from_Simset_params.sh phg.rec ${attenuation_image} 2>&1 >> ${log}
fi

echo "All done!"

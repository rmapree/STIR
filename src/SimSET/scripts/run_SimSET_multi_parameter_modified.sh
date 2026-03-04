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
# SIMSET_DIR=/home/treeves/Software/2.9.2

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
    TEMPLATE_PHG=template_phg.rec
fi
echo "Using ${TEMPLATE_PHG}"

if [ $# -ne 0 -o -z "${TEMPLATE_BIN}" ]; then
    TEMPLATE_BIN=template_bin_EW.rec
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





echo "DIR_OUTPUT = ${DIR_OUTPUT}"



log="${DIR_OUTPUT}/convert_SimSET_STIR.log"
echo "Starting conversion to STIR format (log in ${log}) ..."
: > "$log"   # truncate/create

# find output filenames (read from the same directory you wrote phg.rec into)
activity_image=$(find_param "${DIR_OUTPUT}/phg.rec" activity_image | tr -d '"')
attenuation_image=$(find_param "${DIR_OUTPUT}/phg.rec" attenuation_image | tr -d '"')

# convert: read SimSET outputs from DIR_OUTPUT (not DIR_INPUT)
for (( i=360; i<=520; i+=20 )); do
  bin_file="${DIR_INPUT}/bin_min${i}_crystal.rec"
  if [[ ! -e "$bin_file" ]]; then
    echo "$(date -Iseconds) WARNING: missing $bin_file" | tee -a "$log"
    continue
  fi
  scatter_parameter=$(find_param "$bin_file" scatter_param | tr -d '"' | xargs)
  weight_filename="${DIR_OUTPUT}/rec_min${i}.weight"
  echo "$(date -Iseconds) Converting $bin_file -> $weight_filename" | tee -a "$log"
  conv_SimSET_projdata_to_STIR_energy_windows.sh \
    "$weight_filename" "$num_seg" "$SCANNER" "$i" "$scatter_parameter" >> "$log" 2>&1
done


echo "All done!"


#! /bin/bash

# This is an example run with the templates distributed with STIR (appropriate for the HR+).
# The code below works in bash, sh, ksh etc, but needs to be modified for csh.
# Authors: Kris Thielemans
#
#
#  Copyright (C) 2005 - 2006, Hammersmith Imanet Ltd
#  Copyright (C) 2011-07-01 - 2012, Kris Thielemans
#  This file is part of STIR.
#
#  SPDX-License-Identifier: Apache-2.0
#
#  See STIR/LICENSE.txt for details

# adjust location of SimSET to where you have it installed.
# set SIMSET_DIR if it isnt set by the user
: ${SIMSET_DIR:=/home/treeves/2.9.2}
export SIMSET_DIR

PATH=/home/treeves/devel/build/sources/STIR/src/SimSET/scripts:$PATH


#All STIR utilities/scripts have to be in your path, e.g. if your 
#INSTALL_PREFIX was ~/STIR-bin, you could do
#   PATH=$PATH:~/STIR-bin/bin

# generate emission image
# generate_image generate_uniform_cylinder.par 
# use the same size for the attenuation in this example
# above par file sets image values to 1, so line below will use water for attenuation

# give the simulation a name. All output files will go into a new subdirectory of this name
SIM_NAME=/SAN/medic/Energy_PET_STIR_Sims/SimSET_Data_output/XCAT_brain_test_omni_downsampled
# number of decays to simulate
PHOTONS=70000000
# specify names/locations of input files
EMISS_DATA=/SAN/medic/Energy_PET_STIR_Sims/Image_Data/XCAT_data/XCAT_act_resample_171_2nd_downsample.hv
ATTEN_DATA=/SAN/medic/Energy_PET_STIR_Sims/Image_Data/XCAT_data/XCAT_resample_171_2nd_downsample_empty_atten.hv
templ_dir=/home/treeves/devel/build/sources/STIR/src/SimSET/examples
DIR_INPUT=/home/treeves/devel/build/sources/STIR/src/SimSET/examples
TEMPLATE_PHG=${templ_dir}/template_phg_omni.rec
#TEMPLATE_BIN=${templ_dir}/template_bin.rec
#TEMPLATE_BIN_2=${templ_dir}/template_bin_energy_params_2.rec
TEMPLATE_DET=${templ_dir}/Omni_files/detConfig/omni70cm_6R_31_May_2020_new.detcfg
# specify scanner
SCANNER="GE Discovery 690"
# maximum ring difference to store in conversion from SimSET to Interfile projdata
NUM_SEG=0
# export all variables
export SIM_NAME EMISS_DATA ATTEN_DATA TEMPLATE_PHG TEMPLATE_DET  
export PHOTONS NUM_SEG SCANNER
export DIR_INPUT
DIR_OUTPUT=${SIM_NAME}
export DIR_OUTPUT


# set the simulation going
run_SimSET_omni.sh

echo "Current working directory: $(pwd)"

# Start phg in background
#$SIMSET_DIR/bin/phg "${DIR_OUTPUT}/phg.rec" > "${DIR_OUTPUT}/phg.log" 2>&1 &

PHG_PID=$!

# Wait for phg to finish
wait $PHG_PID


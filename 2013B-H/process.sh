#!/bin/bash
# Run the Moving Object Pipeline on the given exposure numbers
source ${HOME}/.bash_profile

export DBIMAGES=vos:OSSOS/dbimages/
export MEASURE3=vos:OSSOS/measure3/2013B-H/
export rmax=15.0
export rmin=0.5
export ang=-90
export width=90
export field=$4

basedir=`pwd`

for ccd in {0..35} 
  do
  mkdir ${ccd}
  cd ${ccd}
  ## First do the search images
  mkpsf.py $1 $2 $3 -v --ccd ${ccd}
  step1.py $1 $2 $3 -v --ccd ${ccd}
  step2.py $1 $2 $3 -v --ccd ${ccd}
  step3.py $1 $2 $3 -v --rate_min 0.5 --angle -90 --width 90  --ccd ${ccd}
  echo "Running combine.py"
  combine.py $1 -v --measure3 ${MEASURE3} --field ${field}  --ccd ${ccd}

  # First scramble the images.
  scramble.py $1 $2 $3 --ccd $ccd -v --dbimages ${DBIMAGES} 

  # now run the standard pipeline on the scramble images..
  mkpsf.py $1 $2 $3 --ccd $ccd -v --type s --dbimages ${DBIMAGES} 
  step1.py $1 $2 $3 --ccd $ccd -v --type s --dbimages ${DBIMAGES} 
  step2.py $1 $2 $3 --ccd $ccd -v --type s --dbimages ${DBIMAGES} 
  step3.py $1 $2 $3 --ccd $ccd -v --type s --dbimages ${DBIMAGES} --rate_min ${rmin} --rate_max ${rmax} --angle ${ang} --width ${width}
  combine.py $1 --ccd $ccd --type s -v --dbimages ${DBIMAGES} --measure3 ${MEASURE3} --field ${field}

  # Now plant artificial sources.
  plant.py $1 $2 $3 --ccd $ccd -v --dbimages ${DBIMAGES} --type s --rmin ${rmin} --rmax ${rmax} --ang ${ang} --width ${width} 

  # Now run the standard pipeline on the artificial sources.
  mkpsf.py $1 $2 $3 --ccd $ccd --fk -v --type s --dbimages ${DBIMAGES} --type s
  step1.py $1 $2 $3 --ccd $ccd --fk --type s -v --dbimages ${DBIMAGES} 
  step2.py $1 $2 $3 --ccd $ccd --fk --type s -v --dbimages ${DBIMAGES} 
  step3.py $1 $2 $3 --ccd $ccd --fk --type s -v --dbimages ${DBIMAGES} --rate_min ${rmin} --rate_max ${rmax} --angle ${ang} --width ${width} 
  combine.py $1 --ccd $ccd --fk --type s -v --dbimages ${DBIMAGES} --measure3 ${MEASURE3}

  # compute the variation in magnitudes from planeted images
  astrom_mag_check.py fk_${field}_s${ccd}.measure3.cands.astrom  --dbimages ${DBIMAGES}
  vcp fk_${field}_s${ccd}.measure3.cands.match ${MEASURE3}
  cd ${basedir}
done

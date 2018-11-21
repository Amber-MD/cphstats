#!/bin/sh

/bin/rm -f md?_ceout.E_0.75000.gz

EXE=../cestats

NFAIL=0

if [ ! -z "$1" -a "$1" = "clean" ]; then
   /bin/rm -f md?_ceout.E_?.?????
   /bin/rm -f *.dat
   /bin/rm -f *.calceo
   /bin/rm -f *.txt
   exit 0
fi

if [ ! -x $EXE ]; then
   echo "Could not find cestats in the previous directory."
   echo "Re-install, then test again."
   exit 1
fi

compare() {
   echo "Comparing $1 with $2"

   if [ ! -f $1 -o ! -f $2 ]; then
      NFAIL=`echo "$NFAIL + 1" | bc`
      echo "FAILED: Missing file $1 and/or $2!"
      echo "============================================================"
      return 0
   fi

   diff $1 $2 > tmp 2>&1

   if [ $? -eq 0 ]; then
      echo "PASSED"
      echo "============================================================"
      /bin/rm -f tmp
   else
      echo "POSSIBLE FAILURE: check $2.diff"
      echo "============================================================"
      /bin/mv tmp $2.diff
      NFAIL=`echo "$NFAIL + 1" | bc`
   fi
}

# First unpack the REMD files

for i in 2 3 4 5; do
   $EXE -O --fix-remd md${i}_ceout E*/lys-iron.md$i.ceout
done

# Diff some of them

compare md2_ceout.E_0.75000.save md2_ceout.E_0.75000
compare md3_ceout.E_0.81000.save md3_ceout.E_0.81000
compare md4_ceout.E_0.84000.save md4_ceout.E_0.84000
compare md5_ceout.E_0.90000.save md5_ceout.E_0.90000

# Check the calcpka output
$EXE -O -i lys-iron.cein md?_ceout.E_0.75000 -o E_0.75.calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.78000 -o E_0.78.calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 -o E_0.81.calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.84000 -o E_0.84.calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.87000 -o E_0.87.calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.90000 -o E_0.90.calceo

compare E_0.75.calceo.save E_0.75.calceo
compare E_0.78.calceo.save E_0.78.calceo
compare E_0.81.calceo.save E_0.81.calceo
compare E_0.84.calceo.save E_0.84.calceo
compare E_0.87.calceo.save E_0.87.calceo
compare E_0.90.calceo.save E_0.90.calceo

# Check reading of gzipped ceouts
for ceout in md?_ceout.E_0.75000; do
   gzip -9 $ceout
done
$EXE -O -i lys-iron.cein md?_ceout.E_0.75000.gz -o E_0.75.calceo \
     --debug > cestats_output.txt

compare E_0.75.calceo.save E_0.75.calceo
compare cestats_output.txt.save cestats_output.txt

# Check running averages
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     -r 10000 --no-calceo -n 100
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     -r 10000 -R running_avg.dat -d --no-calceo -n 1000
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     -r 10000 -R running_Eo.dat -a --no-calceo -n 5000

compare running_avgs.dat.save running_avgs.dat
compare running_avg.dat.save running_avg.dat
compare running_Eo.dat.save running_Eo.dat

# Check chunk averages
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --chunk 1000 --no-calceo
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --chunk 1000 --chunk-out chunk_oxid.dat --no-calceo -d
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --chunk 1000 --chunk-out chunk_eo.dat --no-calceo -a

compare chunk.dat.save chunk.dat
compare chunk_oxid.dat.save chunk_oxid.dat
compare chunk_eo.dat.save chunk_eo.dat

# Check cumulative output
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --cumulative --no-calceo -n 1000
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --cumulative --no-calceo -n 1000 -d \
     --cumulative-out cumulative_oxid.dat
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --cumulative --no-calceo -n 1000 -a \
     --cumulative-out cumulative_eo.dat

compare cumulative.dat.save cumulative.dat
compare cumulative_oxid.dat.save cumulative_oxid.dat
compare cumulative_eo.dat.save cumulative_eo.dat

# Check the population output
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --population pop.dat --no-calceo

compare pop.dat.save pop.dat

# Check the conditional probability output
$EXE -O -i lys-iron.cein md?_ceout.E_0.81000 \
     --no-calceo -c 4:oxid \
     --conditional-output conditional.dat \
     --chunk-conditional conditional_chunks.dat

compare conditional.dat.save conditional.dat
compare conditional_chunks.dat.save conditional_chunks.dat

# Testing CPEIN funcitonality
$EXE -O -i tyx.cpein tyx.cpeout --debug > cestats_output.cpe.txt

compare cestats_output.cpe.txt.save cestats_output.cpe.txt

echo ""
if [ $NFAIL -ne 0 ]; then
   echo "Detected $NFAIL failure(s)."
   exit 1
else
   echo "All tests passed."
   exit 0
fi
echo ""

#!/bin/sh

/bin/rm -f md?_cpout.pH_2.00.gz

EXE=../cphstats

NFAIL=0

if [ ! -z "$1" -a "$1" = "clean" ]; then
   /bin/rm -f md?_cpout.pH_?.??
   /bin/rm -f *.dat
   /bin/rm -f *.calcpka
   /bin/rm -f *.txt
   exit 0
fi

if [ ! -x $EXE ]; then
   echo "Could not find cphstats in the previous directory."
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
   $EXE -O --fix-remd md${i}_cpout pH*/1AKI.dry.md$i.cpout
done

# Diff some of them

compare md2_cpout.pH_2.00.save md2_cpout.pH_2.00
compare md3_cpout.pH_4.50.save md3_cpout.pH_4.50
compare md4_cpout.pH_7.50.save md4_cpout.pH_7.50
compare md5_cpout.pH_5.00.save md5_cpout.pH_5.00


# Check the calcpka output
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_2.00 -o pH_2.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_2.50 -o pH_2.50.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_3.00 -o pH_3.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_3.50 -o pH_3.50.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 -o pH_4.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.50 -o pH_4.50.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_5.00 -o pH_5.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_5.50 -o pH_5.50.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_6.00 -o pH_6.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_6.50 -o pH_6.50.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_7.00 -o pH_7.00.calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_7.50 -o pH_7.50.calcpka

compare pH_2.00.calcpka.save pH_2.00.calcpka
compare pH_2.50.calcpka.save pH_2.50.calcpka
compare pH_3.00.calcpka.save pH_3.00.calcpka
compare pH_3.50.calcpka.save pH_3.50.calcpka
compare pH_4.00.calcpka.save pH_4.00.calcpka
compare pH_4.50.calcpka.save pH_4.50.calcpka
compare pH_5.00.calcpka.save pH_5.00.calcpka
compare pH_5.50.calcpka.save pH_5.50.calcpka
compare pH_6.00.calcpka.save pH_6.00.calcpka
compare pH_6.50.calcpka.save pH_6.50.calcpka
compare pH_7.00.calcpka.save pH_7.00.calcpka
compare pH_7.50.calcpka.save pH_7.50.calcpka

# Check reading of gzipped cpouts
for cpout in md?_cpout.pH_2.00; do
   gzip -9 $cpout
done
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_2.00.gz -o pH_2.00.calcpka \
     --debug > cphstats_output.txt

compare pH_2.00.calcpka.save pH_2.00.calcpka
compare cphstats_output.txt.save cphstats_output.txt

# Check running averages
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     -r 100000 --no-calcpka -n 100
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     -r 100000 -R running_avg.dat -d --no-calcpka -n 1000
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     -r 100000 -R running_pKa.dat -a --no-calcpka -n 5000

compare running_avgs.dat.save running_avgs.dat
compare running_avg.dat.save running_avg.dat
compare running_pKa.dat.save running_pKa.dat

# Check chunk averages
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --chunk 1000000 --no-calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --chunk 1000000 --chunk-out chunk_deprot.dat --no-calcpka -d
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --chunk 1000000 --chunk-out chunk_pka.dat --no-calcpka -a

compare chunk.dat.save chunk.dat
compare chunk_deprot.dat.save chunk_deprot.dat
compare chunk_pka.dat.save chunk_pka.dat

# Check cumulative output
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --cumulative --no-calcpka -n 1000 --no-calcpka
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --cumulative --no-calcpka -n 1000 -d --no-calcpka \
     --cumulative-out cumulative_deprot.dat
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --cumulative --no-calcpka -n 1000 -a --no-calcpka \
     --cumulative-out cumulative_pka.dat

compare cumulative.dat.save cumulative.dat
compare cumulative_deprot.dat.save cumulative_deprot.dat
compare cumulative_pka.dat.save cumulative_pka.dat

# Check the population output
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --population pop.dat --no-calcpka

compare pop.dat.save pop.dat

# Check the conditional probability output
$EXE -O -i 1AKI.dry.equil.cpin md?_cpout.pH_4.00 \
     --no-calcpka -c 35:prot,52:0 -c 66:D,48:P \
     --conditional-output conditional.dat \
     --chunk-conditional conditional_chunks.dat

compare conditional.dat.save conditional.dat
compare conditional_chunks.dat.save conditional_chunks.dat

# Testing CPEIN funcitonality
$EXE -O -i tyx.cpein tyx.cpeout --debug > cphstats_output.cpe.txt

compare cphstats_output.cpe.txt.save cphstats_output.cpe.txt

echo ""
if [ $NFAIL -ne 0 ]; then
   echo "Detected $NFAIL failure(s)."
   exit 1
else
   echo "All tests passed."
   exit 0
fi
echo ""

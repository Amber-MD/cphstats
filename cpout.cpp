// cpout.cpp: Includes code to deal with and parse cpout files

#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "cpout.h"
#include "exceptions.h"
#include "string_manip.h"

using namespace std;

CpoutFile::CpoutFile(Cpin* cpin, string const& fname) :
fp_(NULL),
type_(ASCII),
valid_(true),
done_(false),
orig_ph_(0.0f),
#ifdef REDOX
orig_temp0_(0.0f),
#endif
step_size_(0),
nres_(0),
remd_file_(false)
{

   filename_ = fname;
   if (fname.find_last_of(".") != string::npos) {
      // Get the suffix
      string sfx = fname.substr(fname.find_last_of('.'));
      if (sfx == string(".bz2")) {
         type_ = BZIP;
         cerr << "Error: BZIP2 compression not supported!" << endl;
         valid_ = false;
     }else if (sfx == string(".gz"))
         type_ = GZIP;
   }

   // Open up the appropriate file (ASCII or gzip)
   if (type_ == ASCII) {
      fp_ = fopen(fname.c_str(), "r");
      if (fp_ == NULL) {
         cerr << "Failed opening " << fname << " for reading." << endl;
         valid_ = false;
      }

  }else if (type_ == GZIP) {
#     ifdef HASGZ
      gzfp_ = gzopen(fname.c_str(), "r");
      if (gzfp_ == NULL) {
         cerr << "Failed opening gzip file " << fname << endl;
         valid_ = false;
      }
#     else
      cerr << "Error: Compiled without support for GZIP compression!" << endl;
      valid_ = false;
#     endif
   }
   // Parse out the first (full) record to determine some information
   char buf[LINEBUF+1];
   if (valid_ && Gets(buf, LINEBUF)) {
      cerr << "Could not read from " << fname << endl;
      Close();
      valid_ = false;
  }else if (valid_) {
      float trash1;
#ifdef REDOX
      if (cpin->isCpin()) {
        check_ = (sscanf(buf, "Redox potential: %f V Temperature: %f K\n", &orig_ph_, &orig_temp0_) == 2);
      }else {
        check_ = (sscanf(buf, "Solvent pH: %f Redox potential: %f V Temperature: %f K\n", &trash1, &orig_ph_, &orig_temp0_) == 3);
      }
      if (check_) {
#else
      float trash2;
      if (cpin->isCpin()) {
        check_ = (sscanf(buf, "Solvent pH: %f\n", &orig_ph_) == 1);
      }else {
        check_ = (sscanf(buf, "Solvent pH: %f Redox potential: %f V Temperature: %f K\n", &orig_ph_, &trash1, &trash2) == 3);
      }
      if (check_) {
#endif
         Gets(buf, LINEBUF);
         if (sscanf(buf, "Monte Carlo step size: %d\n", &step_size_) != 1) {
            if (cpin->isCpin()) {
#ifdef REDOX
              cerr << "Did not recognize the format of ceout " << fname << "." << endl;
#else
              cerr << "Did not recognize the format of cpout " << fname << "." << endl;
#endif
            }else {
              cerr << "Did not recognize the format of cpeout " << fname << "." << endl;
            }
            valid_ = false;
            Close();
         }
         Gets(buf, LINEBUF); // Time step:
         Gets(buf, LINEBUF); // Time
         // Get the starting time
         if (valid_ && sscanf(buf, "Time: %f\n", &start_time_) != 1) {
            if (cpin->isCpin()) {
#ifdef REDOX
              cerr << "Did not recognize the format of ceout " << fname << "." << endl;
#else
              cerr << "Did not recognize the format of cpout " << fname << "." << endl;
#endif
            }else {
              cerr << "Did not recognize the format of cpeout " << fname << "." << endl;
            }
            valid_ = false;
            Close();
         }

         if (valid_) {
            // I'm satisfied it's a valid cpout here; now come the residues
            Gets(buf, LINEBUF);
            int res;
            int state;
            float pH;
            nres_ = 0;
#ifdef REDOX
            int val = sscanf(buf, "Residue %d State: %d E: %f V\n", &res, &state, &pH);
#else
            int val = sscanf(buf, "Residue %d State: %d pH: %f\n", &res, &state, &pH);
#endif
            remd_file_ = val == 3; // This line should tell us if we have a REMD file
            while (val >= 2) {
               nres_++;
               Gets(buf, LINEBUF);
#ifdef REDOX
               val = sscanf(buf, "Residue %d State: %d E: %f V\n", &res, &state, &pH);
#else
               val = sscanf(buf, "Residue %d State: %d pH: %f\n", &res, &state, &pH);
#endif
            }
            Rewind();
         }
     }else {
         if (cpin->isCpin()) {
#ifdef REDOX
           cerr << "Did not recognize the format of ceout " << fname << "." << endl;
#else
           cerr << "Did not recognize the format of cpout " << fname << "." << endl;
#endif
         }else {
           cerr << "Did not recognize the format of cpeout " << fname << "." << endl;
         }
         Close();
         valid_ = false;
      }
   }
}

CpoutFile::CpoutFile(Cpin* cpin, const char* fname) {
   CpoutFile(cpin, string(fname));
}
#ifdef HASGZ
int CpoutFile::GzGets(char* str, int num) {
   if (gzgets(gzfp_, str, num) == NULL)
      return 1;
   return 0;
}
#endif
int CpoutFile::AsciiGets(char* str, int num) {
   if (fgets(str, num, fp_) == NULL) {
      return 1;
   }
   return 0;
}

Record CpoutFile::GetRecord() {
   char buf[LINEBUF+1];

   if (Gets(buf, LINEBUF)) {
      done_ = true;
      throw CpoutFinished();
   }
   Record result;
   float pH;
   float trash1;
#ifdef REDOX
   float temp0;
#else
   float trash2;
#endif
   int res;
   int state;
   result.pH = 0.0f;
   result.full = false;
#ifdef REDOX
   check_ = (sscanf(buf, "Redox potential: %f V Temperature: %f K\n", &pH, &temp0) == 2);
   if (!check_) {
     check_ = (sscanf(buf, "Solvent pH: %f Redox potential: %f V Temperature: %f K\n", &trash1, &pH, &temp0) == 3);
   }
   if (check_) {
#else
   check_ = (sscanf(buf, "Solvent pH: %f\n", &pH) == 1);
   if (!check_) {
     check_ = (sscanf(buf, "Solvent pH: %f Redox potential: %f V Temperature: %f K\n", &pH, &trash1, &trash2) == 3);
   }
   if (check_) {
#endif
      result.full = true;
      result.pH = pH;
#ifdef REDOX
      result.Temperature = temp0;
#endif
      Gets(buf, LINEBUF); // Monte Carlo step size
      Gets(buf, LINEBUF); // Time step:
      sscanf(buf, "Time step: %d\n", &result.time_step);
      Gets(buf, LINEBUF); // Time:
      sscanf(buf, "Time: %f\n", &result.time);
      Gets(buf, LINEBUF); // Residue
#ifdef REDOX
      while (sscanf(buf, "Residue %d State: %d E: %f V\n", &res, &state, &pH) >= 2) {
#else
      while (sscanf(buf, "Residue %d State: %d pH: %f\n", &res, &state, &pH) >= 2) {
#endif
         RecordPoint pt;
         pt.state = state; pt.residue = res;
         result.points.push_back(pt);
         if (Gets(buf, LINEBUF)) {
            done_ = true;
            Close();
            return result;
         }
      }
      return result;
  }else {
#ifdef REDOX
      int s = sscanf(buf, "Residue %d State: %d E: %f V\n", &res, &state, &pH);
#else
      int s = sscanf(buf, "Residue %d State: %d pH: %f\n", &res, &state, &pH);
#endif
      // If this is a REMD run, assign the pH
      if (s == 3)
         result.pH = pH;
      RecordPoint pt;
      pt.state = state; pt.residue = res;
      result.points.push_back(pt);
      if (Gets(buf, LINEBUF)) {
         done_ = true;
         Close();
         return result;
      }
      // Get more residues from a multi-site move
#ifdef REDOX
      while (sscanf(buf, "Residue %d State: %d E: %f V\n", &res, &state, &pH) >= 2) {
#else
      while (sscanf(buf, "Residue %d State: %d pH: %f\n", &res, &state, &pH) >= 2) {
#endif
         RecordPoint opt;
         opt.state = state; opt.residue = res;
         result.points.push_back(opt);
         if (Gets(buf, LINEBUF)) {
            done_ = true;
            Close();
            return result;
         }
      }
      return result;
   }

#ifdef REDOX
   throw InternalError("Ceout parsing error: should not be here");
#else
   throw InternalError("Cpout parsing error: should not be here");
#endif

   // Will never get here, but need this to eliminate compiler warnings
   return result;
}

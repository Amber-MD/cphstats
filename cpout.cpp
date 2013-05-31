// cpout.cpp: Includes code to deal with and parse cpout files

#include <cstdio>
#include <cstdlib>
#include "cpout.h"
#include "string_manip.h"

CpoutFile::CpoutFile(std::string const& fname) {

   // File type
   type_ = ASCII;
   valid_ = true;
   done_ = false;

   if (fname.find_last_of('.') != std::string::npos) {
      // Get the suffix
      std::string sfx = fname.substr(fname.find_last_of('.'));
      if (sfx == std::string(".bz2")) {
         type_ = BZIP;
         fprintf(stderr, "Error: BZIP2 compression is not supported!\n");
         valid_ = false;
     }else if (sfx == std::string(".gz"))
         type_ = GZIP;
   }

   // Open up the appropriate file
   if (type_ == ASCII) {
      fp_ = fopen(fname.c_str(), "r");
      if (fp_ == NULL) {
         fprintf(stderr, "Failed opening %s for reading.\n", fname.c_str());
         valid_ = false;
      }
         
  }else if (type_ == GZIP) {
      gzfp_ = gzopen(fname.c_str(), "r");
      if (gzfp_ == NULL) {
         fprintf(stderr, "Failed opening gzip file %s\n", fname.c_str());
         valid_ = false;
      }
   }
   
   char* buf;
   if (Gets(buf, LINEBUF)) {
      fprintf(stderr, "Could not read from %s\n", fname.c_str());
      Close();
      valid_ = false;
  }else{
      if (strncmp(buf, "Solvent pH:", 11) == 0)
         if (sscanf(buf, "Solvent pH: %f\n", &orig_ph_) != 1)
            fprintf(stderr, "OH NO!\n");
         Gets(buf, LINEBUF);
         sscanf(buf, "Monte Carlo step size: %d\n", &step_size_);
         fseek(fp_, 0, SEEK_SET);
      else {
         fprintf(stderr, "Did not recognize the format of cpout %s.\n" fname.c_str());
         Close();
         valid_ = false;
      }
   }
}

CpoutFile::CpoutFile(const char* fname) {
   CpoutFile(std::string(fname));
}

int CpoutFile::GzGets(char* str, int num) {
   if (gzgets(gzfp_, str, num) == NULL)
      return 1;
   return 0;
}

int CpoutFile::AsciiGets(char* str, int num) {
   if (fgets(str, num, fp_) == NULL)
      return 1;
   return 0;
}

Record CpoutFile::GetRecord() {
   char* buf;
   if (Gets(buf, LINEBUF)) {
      done_ = true;
      Record empty_record;
      empty_record.pH = 0.0f; empty_record.full = false;
      return empty_record;
   }
   Record result;
   float pH;
   int res, state;
   if (sscanf(buf, "Solvent pH: %f\n", &pH) == 1) {
      result.full = true;
      result.pH = pH;
  }else if (sscanf(buf, "Residue %d State: %d\n", &res, &state) >= 2) {
      RecordPoint pt;
      pt.state = state; pt.residue = res;
      result.points.push_back(pt);
      if (Gets(buf, LINEBUF)) {
         done_ = true;
         Close();
         return result;
      }
      while (sscanf(buf, "Residue %d State: %d\n", &res, &state) == 2) {
         RecordPoint opt;
         opt.state = state; opt.residue = res;
         result.points.push_back(pt);
         if (Gets(buf, LINEBUF)) {
            done_ = true;
            Close();
            return result;
         }
      }
  }else {
      fprintf(stderr, "Unrecognized cpout file!\n");
      Close();
      done_ = true;
      Record empty_record;
      empty_record.pH = 0.0f; empty_record.full = false;
      return empty_record;
   }
}
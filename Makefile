include config.h

.NOTPARALLEL:clean install all

OBJS = main.o cpin.o parse_cpin.o string_manip.o cloptions.o test.o cpout.o \
       prottraj.o utilities.o conprob.o

all: $(PROGNAME)

$(PROGNAME): $(OBJS)
	$(LD) $(LDFLAGS) -o $(PROGNAME) $(OBJS)

install: $(PROGNAME)
	/bin/mv $(PROGNAME) $(PREFIX)/bin

uninstall:
	/bin/rm -f $(PREFIX)/bin/$(PROGNAME)

.SUFFIXES: .F90 .cpp .o

depends::
	./makedepends

.F90.o:
	$(F90) $(F90FLAGS) -c $*.F90

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $*.cpp

clean:
	/bin/rm -f $(OBJS)

new: clean $(PROGNAME)

include depends

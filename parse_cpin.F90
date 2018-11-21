
#include "constants.h"

#ifdef REDOX
subroutine parse_cein(trescnt, eleccnt, stateinf, resname, cein_name, is_cpin, ierr)
#else
subroutine parse_cpin(trescnt, protcnt, stateinf, resname, cpin_name, is_cpin, ierr)
#endif

   implicit none

   ! The stateinf struct
#ifdef REDOX
   type :: const_e_info
#else
   type :: const_ph_info
#endif
      sequence
      integer :: num_states
      integer :: first_atom
      integer :: num_atoms
      integer :: first_state
      integer :: first_charge
#ifdef REDOX
   end type const_e_info
#else
   end type const_ph_info
#endif

   ! The namelist variables

   integer             :: trescnt
   integer             :: is_cpin
   integer             :: protcnt(0:TITR_STATES_C-1)
   integer             :: eleccnt(0:TITR_STATES_C-1)
   integer             :: resstate(0:TITR_RES_C-1)
   integer             :: ierr
   double precision    :: pka_corr(0:TITR_STATES_C-1)
   double precision    :: eo_corr(0:TITR_STATES_C-1)

#ifdef REDOX
   integer             :: cefirst_sol
   integer             :: ce_igb
   double precision    :: ce_intdiel
#else
   integer             :: cphfirst_sol
   integer             :: cph_igb
   double precision    :: cph_intdiel
#endif
   integer             :: cphefirst_sol
   integer             :: cphe_igb
   double precision    :: cphe_intdiel

   double precision    :: statene(0:TITR_STATES_C-1)
   double precision    :: chrgdat(0:ATOM_CHRG_C-1)

   character(len=40)   :: resname(0:TITR_RES_C)

#ifdef REDOX
   type(const_e_info) :: stateinf(0:TITR_RES_C-1)
   type(const_e_info) :: null_cnste_info = const_e_info(0,0,0,0,0)
#else
   type(const_ph_info) :: stateinf(0:TITR_RES_C-1)
   type(const_ph_info) :: null_cnstph_info = const_ph_info(0,0,0,0,0)
#endif

   ! Is our cpin file read yet?

   logical             :: is_read = .false.

#ifdef REDOX
   ! File unit
   integer, parameter  :: CEIN_UNIT = 10

   ! The cein name
   character(len=FN_LEN), intent(in) :: cein_name
#else
   ! File unit
   integer, parameter  :: CPIN_UNIT = 10

   ! The cpin name
   character(len=FN_LEN), intent(in) :: cpin_name
#endif

   ! The public functions

   ! We read it as a namelist
   namelist /cnstphe/ stateinf, resstate, protcnt, eleccnt, chrgdat, statene, &
                      pka_corr, eo_corr, trescnt, resname, cphefirst_sol, &
                      cphe_igb, cphe_intdiel

#ifdef REDOX
   ! We read it as a namelist
   namelist /cnste/ stateinf, resstate, eleccnt, chrgdat, statene, eo_corr, &
                     trescnt, resname, cefirst_sol, ce_igb, ce_intdiel

   ! Initialize the namelist variables
   stateinf(:) = null_cnste_info
   cefirst_sol = 0
   ce_igb = 0
   ce_intdiel = 0.d0
#else
   ! We read it as a namelist
   namelist /cnstph/ stateinf, resstate, protcnt, chrgdat, statene, pka_corr, &
                     trescnt, resname, cphfirst_sol, cph_igb, cph_intdiel

   ! Initialize the namelist variables
   stateinf(:) = null_cnstph_info
   cphfirst_sol = 0
   cph_igb = 0
   cph_intdiel = 0.d0
#endif
   trescnt = 0
   resstate(:) = 0
   protcnt(:) = 0
   eleccnt(:) = 0
   pka_corr(:) = 1000.d0
   eo_corr(:) = 0.d0
   chrgdat(:) = 0.d0
   statene(:) = 0.d0
   resname(:) = ' '
   cphefirst_sol = 0
   cphe_igb = 0
   cphe_intdiel = 0.d0
   ierr = 0

#ifdef REDOX
   ! Open the unit, bailing on error
   open(unit=CEIN_UNIT, file=cein_name, status='OLD', iostat=ierr)
   if (ierr .ne. 0) then
      write(0, '(a)') 'Failed opening the file'
      return
   end if

   ! Read the namelist, bailing on error
   if (is_cpin .eq. 1) then
     read(CEIN_UNIT, nml=cnste, iostat=ierr)
   else
     read(CEIN_UNIT, nml=cnstphe, iostat=ierr)
   end if
   if (ierr .ne. 0) then
      write(0, '(a)') 'Failed reading the file'
      return
   end if
#else
   ! Open the unit, bailing on error
   open(unit=CPIN_UNIT, file=cpin_name, status='OLD', iostat=ierr)
   if (ierr .ne. 0) then
      write(0, '(a)') 'Failed opening the file'
      return
   end if

   ! Read the namelist, bailing on error
   if (is_cpin .eq. 1) then
     read(CPIN_UNIT, nml=cnstph, iostat=ierr)
   else
     read(CPIN_UNIT, nml=cnstphe, iostat=ierr)
   end if
   if (ierr .ne. 0) then
      write(0, '(a)') 'Failed reading the file'
      return
   end if
#endif

   ! If we got this far, then our file is read
   is_read = .true.

   return

#ifdef REDOX
end subroutine parse_cein
#else
end subroutine parse_cpin
#endif

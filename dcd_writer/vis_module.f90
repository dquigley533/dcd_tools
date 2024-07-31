!=============================================================================!
!                               V  I  S                                       !
!=============================================================================!
!                                                                             !
! $Id: vis_module.f90,v 1.8 2011/11/21 14:12:45 phseal Exp $
!                                                                             !
!-----------------------------------------------------------------------------!
! Routines to create psf and dcd files of molecular chains for visualisation. !
! Only linear chains are supported at present.                                !
!-----------------------------------------------------------------------------!
module vis


  use iso_c_binding

  ! Everything private

  !---------------------------------------------------------------------------!
  !                       P u b l i c   R o u t i n e s                       !
  !---------------------------------------------------------------------------!
  !... unless exposed here.

  public :: write_psf            ! Create appropraite protein structure file
  public :: write_dcd_header     ! Write a header for a binary trajectory file
  public :: write_dcd_snapshot   ! Write a snapshot to a binary trajectory file

  !---------------------------------------------------------------------------!
  !                      P r i v a t e   V a r i a b l e s                    !
  !---------------------------------------------------------------------------

  ! For C interopability - use types in iso_c_binding intrinsic module
  integer,parameter    :: dp = c_double
  integer,parameter    :: ep = c_double  ! Change if needing extended precision
  integer,parameter    :: it = c_int
  
  integer(kind=it),save :: psf = 201
  integer(kind=it),save :: dcd = 202

  integer(kind=it),save :: nboxes = 1    ! TODO - pass as optional argument?
  logical,save :: pbc = .true.           ! TODO - pass as optional argument?

  ! Constants
  real(kind=dp),parameter :: Pi = 3.141592653589793238462643383279502884197_dp
  real(kind=dp),parameter :: invPi = 1.0_dp/3.141592653589793238462643383279502884197_dp
    
  
  contains


    function calc_recip_matrix(hmatrix)
      !------------------------------------------------------------------------------!
      ! Calculates the matrix of reciprocal lattive vectors from the hmatrix         !
      !------------------------------------------------------------------------------!
      ! D.Quigley September 2006                                                     !
      !------------------------------------------------------------------------------!
      implicit none
      real(kind=dp),dimension(3,3),intent(in) :: hmatrix
      real(kind=dp) :: vol
      real(kind=dp),dimension(3,3) :: recip_matrix, calc_recip_matrix
      
      ! invert hmatrix to get recip_matrix
      recip_matrix(1,1)=hmatrix(2,2)*hmatrix(3,3)-hmatrix(2,3)*hmatrix(3,2)
      recip_matrix(1,2)=hmatrix(2,3)*hmatrix(3,1)-hmatrix(2,1)*hmatrix(3,3)
      recip_matrix(1,3)=hmatrix(2,1)*hmatrix(3,2)-hmatrix(2,2)*hmatrix(3,1)
      
      recip_matrix(2,1)=hmatrix(1,3)*hmatrix(3,2)-hmatrix(1,2)*hmatrix(3,3)
      recip_matrix(2,2)=hmatrix(1,1)*hmatrix(3,3)-hmatrix(1,3)*hmatrix(3,1)
      recip_matrix(2,3)=hmatrix(1,2)*hmatrix(3,1)-hmatrix(1,1)*hmatrix(3,2)

      recip_matrix(3,1)=hmatrix(1,2)*hmatrix(2,3)-hmatrix(1,3)*hmatrix(2,2)
      recip_matrix(3,2)=hmatrix(1,3)*hmatrix(2,1)-hmatrix(1,1)*hmatrix(2,3)
      recip_matrix(3,3)=hmatrix(1,1)*hmatrix(2,2)-hmatrix(1,2)*hmatrix(2,1)

      ! Calculate cell volume
      vol =hmatrix(1,1)*recip_matrix(1,1) + &
           hmatrix(1,2)*recip_matrix(1,2) + &
           hmatrix(1,3)*recip_matrix(1,3)

      ! Scale reciprocal lattice by 2*pi/volume
      recip_matrix(:,:)=recip_matrix(:,:)*2.0_dp*Pi/vol

      calc_recip_matrix = recip_matrix

    end function calc_recip_matrix

    
    subroutine write_psf(nchains, nbeads) bind(c)
      !------------------------------------------------------!
      ! Writes a VMD compatible psf file for a linear chain  !
      ! of bonded beads. The symbol for carbon is used for   !
      ! each bead, this is an arbitary choice. The radius    !
      ! of the beads can be changed once loaded into vmd.    !
      !------------------------------------------------------!
      ! D.Quigley January 2010                               !
      !------------------------------------------------------!
      implicit none
      integer(kind=it),value,intent(in) :: nchains,nbeads

      integer,allocatable,dimension(:) :: arrbonds

      integer(kind=it) :: i,ierr,j,k,ichain
      character(3)     :: boxstring
      character(30)    :: filename


      if (nboxes == 1) then
         ! open the psf file
         open(unit=psf,file='chain.psf',status='replace',iostat=ierr)
         if (ierr/=0) stop 'Error opening chain.psf for output'
      else
         write(boxstring,'(".",I2.2)')1
         filename = 'chain.psf'//boxstring
         open(unit=psf,file=trim(filename),status='replace',iostat=ierr)
         if (ierr/=0) stop 'Error opening chain psf files for output'
      end if
      
      ! write the header
      write(psf,'(A3)')'PSF'
      write(psf,'("         1 !NTITLE")')
      write(psf,*)
      write(psf,'(I8,1x,"!NATOM")')nchains*nbeads

      ! format for x-plor style psf
10    format(I8,1x,A4,1x,I4,1x,A4,1x,A4,1x,A5,1x,F10.6,1x,5x,F8.4,10x,"0")

      ! Write the atoms information. The last entry is the mass
      ! which will be ignored by VMD anyway.
      k = 1
      do ichain = 1,nchains
         do j = 1,nbeads
            write(psf,10)k,"BULK",ichain,"UNK ","C   ","C    ",0.0,1.0
            k = k + 1
         end do
      end do
      
      ! Write the number of bonds
      write(psf,*)
      write(psf,'(I8,1x,"!NBOND: bonds")')nchains*(nbeads-1)
      
      ! Construct the array of bonding information
      allocate(arrbonds(1:2*nchains*(nbeads-1)),stat=ierr)
      if (ierr/=0) stop 'Error allocating bonds array in write_psf'
      k = 1
      do ichain = 1,nchains
         do i = 1,Nbeads-1
            arrbonds(k)   = (ichain-1)*nbeads+i
            arrbonds(k+1) = (ichain-1)*nbeads+i+1
            k = k + 2
         end do
      end do
      
      ! Write the bonding information in the correct format
30    format(1x,I7,1x,I7,1x,I7,1x,I7,1x,I7,1x,I7,1x,I7,1x,I7,1x)
      write(psf,30)arrbonds
      
      ! write irrelevant stuff 
      write(psf,'(I8,1x,"!NTHETA: angles")')0
      write(psf,'(I8,1x,"!NPHI: torsions")')0
      write(psf,'(I8,1x,"!NIMPHI: torsions")')0
      write(psf,'(I8,1x,"!NDON: donors")')0
      write(psf,'(I8,1x,"!NACC: acceptors")')0
      
      close(psf)
      deallocate(arrbonds)
      
      return

    end subroutine write_psf

  subroutine write_dcd_header(Nchains,Nbeads) bind(c)
    !------------------------------------------------------!
    ! Writes the header of a VMD compatible dcd file for a !
    ! linear chain of bonded beads.                        !
    !------------------------------------------------------!
    ! D.Quigley January 2010                               !
    !------------------------------------------------------!
    implicit none
    integer(kind=it),value,intent(in) :: Nchains,Nbeads

    ! arrays for header
    integer,dimension(20) :: icntrl
    character(4) :: hdr='CORD'
    character*80,dimension(32) :: dcdtitle

    integer(kind=it) :: i,ierr
    character(3)     :: boxstring
    character(30)    :: filename

    dcdtitle = 'DCD file written by hs_alkane'

    if (nboxes == 1) then
       ! open the psf file
       open(unit=dcd,file='chain.dcd',status='replace',iostat=ierr,form='unformatted')
       if (ierr/=0) stop 'Error opening chain.dcd file - quitting'
    else
       write(boxstring,'(".",I2.2)')1
       filename = 'chain.dcd'//boxstring
       open(unit=dcd,file=trim(filename),status='replace',iostat=ierr,form='unformatted')
       if (ierr/=0) stop 'Error opening chain dcd files - quitting'
    end if
    
    ! write the dcd header - most of this will be ignored
    icntrl(1)     = 1000              ! number of snapshots in history file
    icntrl(2)     = 0
    icntrl(3)     = 100               ! gap in steps between snapshots (doesn't matter)
    icntrl(4)     = 100*1000          ! total number of steps (VMD ignores this)
    icntrl(5:7)   = 0
    icntrl(8)     = 3*Nchains*Nbeads  ! Ndeg
    icntrl(9)     = 0                 ! no fixed atoms
    icntrl(10)    = 0
    icntrl(11)    = 1                 ! 1/0 for unit cell presence
    icntrl(12:19) = 0
    icntrl(20)    = 24                ! Charmm version number (fixes dcd format)
    
    write(dcd)hdr,icntrl
    write(dcd)1,(dcdtitle(i),i=1,1)
    write(dcd)Nchains*nbeads
    
    close(dcd)
    

    return

  end subroutine write_dcd_header

  subroutine write_dcd_snapshot(nchains,nbeads,ndims1,rchain,hmatrix) bind(c)
    !------------------------------------------------------!
    ! Writes a snapshot of the current positions to a the  !
    ! dcd file. Expects a 2D array r(1:3,1:nchain) in      !
    ! double precision which holds the coordinates.        !
    !------------------------------------------------------!
    ! D.Quigley January 2010                               !
    !------------------------------------------------------!
    implicit none

    integer(kind=it),value,intent(in) :: nchains,nbeads,ndims1  ! Dimensions for rchain

    real(kind=dp),dimension(ndims1,nbeads,nchains),intent(in) :: rchain
    real(kind=dp),dimension(3,3),intent(in) :: hmatrix
    real(kind=dp),dimension(3,3) :: recip_matrix
    
    real(kind=dp),allocatable,dimension(:,:,:) :: rcopy
    real(kind=dp),dimension(3) :: rcom,oldcom,tmpcom,comchain
    real(kind=dp),dimension(3) :: unita,unitb,unitc

    ! charmm style cell vector array
    real(kind=ep),dimension(6) :: xtlabc

    integer(kind=it) :: ierr,j,i,ichain,ibead

    character(3)  :: boxstring
    character(30) :: filename

    allocate(rcopy(1:3,1:nbeads,1:nchains),stat=ierr)
    if (ierr/=0) stop 'Error allocating rcopy in write_dcd_snapshot'

    recip_matrix = calc_recip_matrix(hmatrix)
    
    
!!$    do ichain = 1,nchains
!!$       do j = 1,nbeads
!!$          rcopy(1,j,ichain) = r(1,j,ichain) - Lx*anint(r(1,j,ichain)*rLx)
!!$          rcopy(2,j,ichain) = r(2,j,ichain) - Ly*anint(r(2,j,ichain)*rLy)
!!$          rcopy(3,j,ichain) = r(3,j,ichain) - Lz*anint(r(3,j,ichain)*rLz)
!!$       end do
!!$    end do


!!$    rcopy = r

    do ichain = 1,nchains

       
       ! Find center of mass and the vector which translates
       ! it back inside the unit cell.
       comchain(:) = 0.0_dp
       do ibead = 1,nbeads
          comchain(:) = comchain(:) + rchain(:,ibead,ichain)
       end do
       comchain(:) = comchain(:)/real(nbeads,kind=dp)
       oldcom(:)   = comchain(:)
       
       tmpcom(1) = recip_matrix(1,1)*oldcom(1) + &
                   recip_matrix(2,1)*oldcom(2) + &
                   recip_matrix(3,1)*oldcom(3)
       tmpcom(2) = recip_matrix(1,2)*oldcom(1) + &
                   recip_matrix(2,2)*oldcom(2) + &
                   recip_matrix(3,2)*oldcom(3)
       tmpcom(3) = recip_matrix(1,3)*oldcom(1) + &
                   recip_matrix(2,3)*oldcom(2) + &
                   recip_matrix(3,3)*oldcom(3)
       
       tmpcom    = tmpcom*0.5_dp*invPi
       
       oldcom(1) = - anint(tmpcom(1))
       oldcom(2) = - anint(tmpcom(2))
       oldcom(3) = - anint(tmpcom(3))
       
       tmpcom(1) = hmatrix(1,1)*oldcom(1) + &
                   hmatrix(1,2)*oldcom(2) + &
                   hmatrix(1,3)*oldcom(3)
       
       tmpcom(2) = hmatrix(2,1)*oldcom(1) + &
                   hmatrix(2,2)*oldcom(2) + &
                   hmatrix(2,3)*oldcom(3)
       
       tmpcom(3) = hmatrix(3,1)*oldcom(1) + &
                   hmatrix(3,2)*oldcom(2) + &
                   hmatrix(3,3)*oldcom(3)

       ! Apply to all beads in a chain
       do ibead = 1,nbeads
          rcopy(:,ibead,ichain) = rchain(:,ibead,ichain) + tmpcom(:)
       end do
       
    end do

    ! Special treatment for single chain with no pbc
    if ( (nchains==1).and.(.not.pbc) ) then
       rcom = 0.0_dp
       do i = 1,nbeads
          rcom(:) = rcom(:) + rchain(:,i,1)
       end do
       rcom(:) = rcom(:)/real(nbeads,kind=dp)
       do i = 1,nbeads
          rcopy(:,i,1) = rchain(:,i,1) - rcom(:)
       end do
    end if
    
    if (nboxes==1) then
       open(unit=dcd,file='chain.dcd',status='old',position='append',iostat=ierr,form='unformatted')
       if (ierr/=0) stop 'Error opening chain.dcd file - quitting'
    else
       write(boxstring,'(".",I2.2)')1
       filename = 'chain.dcd'//boxstring
       open(unit=dcd,file=trim(filename),status='old',position='append',iostat=ierr,form='unformatted')
       if (ierr/=0) stop 'Error opening chain dcd files - quitting'
    end if
    
    ! Specify an abritary periodic box. It doesn't matter that we aren't using
    ! periodic boundaries - vmd will ignore this information unless we ask it
    ! to do otherwise.
    xtlabc(1) = sqrt(dot_product(hmatrix(:,1),hmatrix(:,1)))
    xtlabc(3) = sqrt(dot_product(hmatrix(:,2),hmatrix(:,2)))
    xtlabc(6) = sqrt(dot_product(hmatrix(:,3),hmatrix(:,3)))
    
    unita(:)  = hmatrix(:,1)/xtlabc(1)
    unitb(:)  = hmatrix(:,2)/xtlabc(3)
    unitc(:)  = hmatrix(:,3)/xtlabc(6)

    xtlabc(2) = acos(dot_product(unita,unitb))*180.0*invPi
    xtlabc(4) = acos(dot_product(unita,unitc))*180.0*invPi
    xtlabc(5) = acos(dot_product(unitb,unitc))*180.0*invPi

    ! We want the acute angles
    if (xtlabc(4) > 90.0_dp ) xtlabc(4) = 180.0 - xtlabc(4)
    if (xtlabc(5) > 90.0_dp ) xtlabc(5) = 180.0 - xtlabc(5)

    
    ! Write the information to file, note conversion to single
    ! precision to save on file size.
    write(dcd)xtlabc
    write(dcd)((-real(rcopy(1,i,j),kind=4),i=1,Nbeads),j=1,nchains)
    write(dcd)((-real(rcopy(2,i,j),kind=4),i=1,Nbeads),j=1,nchains)
    write(dcd)((real(rcopy(3,i,j),kind=4),i=1,Nbeads),j=1,nchains)
    
    !call flush(dcd)
    close(dcd)

    deallocate(rcopy,stat=ierr)
    if (ierr/=0) stop 'Error releasing rcopy in write_dcd_snapshot'

  end subroutine write_dcd_snapshot

end module vis

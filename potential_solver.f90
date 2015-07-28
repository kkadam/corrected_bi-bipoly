!*************************************************************
!*
!*  POTENTIAL_SOLVER
!*
!*************************************************************
subroutine potential_solver
implicit none
include 'runscf.h'
!*************************************************************
!*
!  potential_solver is the driver porgram for solving
!  Poisson's equation
!* 
!*************************************************************
!*
!*   Global Variables

real, dimension(numr,numz,numphi) :: pot, rho
common /poisson/ pot, rho

real, dimension(numr,numz,numphi) :: potp, rhop
common /potarrays/ potp, rhop

real :: dt, time, dt_visc
integer :: tstep
common /timestep/ dt, time, dt_visc, tstep

integer, dimension(3) :: boundary_condition
common /boundary_conditions/ boundary_condition

logical :: iam_on_top, iam_on_bottom, iam_on_axis,           &
           iam_on_edge, iam_root
integer :: column_num, row_num
integer :: iam, down_neighbor, up_neighbor,                  &
           in_neighbor, out_neighbor, root,                  &
           REAL_SIZE, INT_SIZE

common /processor_grid/ iam, iam_on_top,           &
                        iam_on_bottom, iam_on_axis,          &
                        iam_on_edge, down_neighbor,          &
                        up_neighbor, in_neighbor,            &
                        out_neighbor, root, column_num,      &
                        row_num, iam_root,          &
                        REAL_SIZE, INT_SIZE

!*
!*************************************************************
!*
!*  Local Variables

integer :: nsteps

!*
!*************************************************************
!  initialize the local variable
nsteps = 0

! copy the density array into a workspace copy
rhop = rho
! need to zero out sections of rhop to avoid problems
! with material piling up in the boundary zones for
! the dirichlet boundary conditions
   rhop(:,zupb:zupb+1,:) = 0.0
   rhop(rupb:rupb+1,:,:) = 0.0
if (isym == 1) then
   rhop(:,zlwb-1:zlwb,:) = 0.0
endif

if( tstep > 1 ) then
   ! have a previous set of values for the potential
   ! it has either been read in from the continuation
   ! file by setup or exists from the end of the last
   ! time potential_solver was called.  Perform only
   ! 5 ADI iterations as we are starting from a good
   ! guess for the potential
   !nsteps = 20
   nsteps = 10
else
   ! don't have a guess for the potential but 20 ADI
   ! iterations are sufficient for a cold start to
   ! get an acceptable solution
   !nsteps = 50
   nsteps = 50
   potp = 0.0
endif

! solve for the boundary values of the potential
call bessel 

! solve Poisson's equation
call helmadi(nsteps)
  
! fill in the potential with the solution
! if you want to add an external potential in
! addition to the self gravity this would be a
! good place to do it
pot = potp

return
end subroutine potential_solver

module aurora_fortran_runtime
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  private
  public :: aurora_zero_i32
  public :: aurora_abort

contains

  subroutine aurora_zero_i32(values, count) bind(c, name="aurora_zero_i32")
    integer(c_int32_t), intent(out) :: values(*)
    integer(c_int32_t), value :: count
    integer :: i

    do i = 1, count
      values(i) = 0_c_int32_t
    end do
  end subroutine aurora_zero_i32

  subroutine aurora_abort(code) bind(c, name="aurora_abort")
    integer(c_int32_t), value :: code

    stop code
  end subroutine aurora_abort

end module aurora_fortran_runtime


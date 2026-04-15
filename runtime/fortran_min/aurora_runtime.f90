subroutine aurora_zero_i32(values, count) bind(c, name="aurora_zero_i32")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), intent(out) :: values(*)
  integer(c_int32_t), value :: count
  integer :: i

  do i = 1, count
    values(i) = 0_c_int32_t
  end do
end subroutine aurora_zero_i32

subroutine aurora_abort(code) bind(c, name="aurora_abort")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), value :: code
  interface
    subroutine c_abort() bind(c, name="abort")
    end subroutine c_abort
  end interface

  if (code /= 0_c_int32_t) then
    call c_abort()
  end if
end subroutine aurora_abort

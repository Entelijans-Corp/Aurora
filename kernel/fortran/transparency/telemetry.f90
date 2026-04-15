subroutine aurora_compute_kernel_profile( &
    object_count, &
    capability_count, &
    endpoint_count, &
    region_count, &
    module_count, &
    queued_messages, &
    scheduler_ticks, &
    metrics, &
    metrics_count &
) bind(c, name="aurora_compute_kernel_profile")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), value :: object_count
  integer(c_int32_t), value :: capability_count
  integer(c_int32_t), value :: endpoint_count
  integer(c_int32_t), value :: region_count
  integer(c_int32_t), value :: module_count
  integer(c_int32_t), value :: queued_messages
  integer(c_int32_t), value :: scheduler_ticks
  integer(c_int32_t), intent(inout) :: metrics(*)
  integer(c_int32_t), value :: metrics_count
  integer(c_int32_t) :: transparency_score
  integer(c_int32_t) :: pressure_score
  integer(c_int32_t) :: evolution_score

  interface
    subroutine aurora_zero_i32(values, count) bind(c, name="aurora_zero_i32")
      use, intrinsic :: iso_c_binding, only: c_int32_t
      implicit none
      integer(c_int32_t), intent(out) :: values(*)
      integer(c_int32_t), value :: count
    end subroutine aurora_zero_i32
  end interface

  call aurora_zero_i32(metrics, metrics_count)

  if (metrics_count < 3_c_int32_t) return

  transparency_score = 20_c_int32_t * module_count + &
      12_c_int32_t * region_count + &
      8_c_int32_t * endpoint_count + &
      5_c_int32_t * object_count + &
      4_c_int32_t * capability_count

  pressure_score = 18_c_int32_t * queued_messages + &
      6_c_int32_t * capability_count + &
      3_c_int32_t * object_count - &
      8_c_int32_t * module_count

  evolution_score = 15_c_int32_t * module_count + &
      10_c_int32_t * min(5_c_int32_t, scheduler_ticks) + &
      8_c_int32_t * endpoint_count + &
      4_c_int32_t * capability_count

  metrics(1) = min(100_c_int32_t, transparency_score)
  metrics(2) = min(100_c_int32_t, max(0_c_int32_t, pressure_score))
  metrics(3) = min(100_c_int32_t, evolution_score)
end subroutine aurora_compute_kernel_profile

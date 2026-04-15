integer(c_int32_t) function aurora_compute_timeslice(run_queue_depth, base_slice) bind(c, name="aurora_compute_timeslice")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), value :: run_queue_depth
  integer(c_int32_t), value :: base_slice
  integer(c_int32_t) :: contention_penalty

  contention_penalty = max(0_c_int32_t, run_queue_depth - 1_c_int32_t)
  aurora_compute_timeslice = max(1_c_int32_t, base_slice - contention_penalty)
end function aurora_compute_timeslice

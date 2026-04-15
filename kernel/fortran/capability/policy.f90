function aurora_capability_can_transfer( &
    permission_mask, &
    source_owner, &
    new_owner, &
    generation &
) result(allowed) bind(c, name="aurora_capability_can_transfer")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), value :: permission_mask
  integer(c_int32_t), value :: source_owner
  integer(c_int32_t), value :: new_owner
  integer(c_int32_t), value :: generation
  integer(c_int32_t), parameter :: transfer_bit = 4_c_int32_t
  integer(c_int32_t) :: allowed

  allowed = 0_c_int32_t

  if (iand(permission_mask, transfer_bit) == 0_c_int32_t) return
  if (source_owner == new_owner) return
  if (generation >= 64_c_int32_t) return

  allowed = 1_c_int32_t
end function aurora_capability_can_transfer

function aurora_capability_risk_score( &
    permission_mask, &
    generation &
) result(score) bind(c, name="aurora_capability_risk_score")
  use, intrinsic :: iso_c_binding, only: c_int32_t
  implicit none
  integer(c_int32_t), value :: permission_mask
  integer(c_int32_t), value :: generation
  integer(c_int32_t) :: score

  score = 0_c_int32_t

  if (iand(permission_mask, 1_c_int32_t) /= 0_c_int32_t) score = score + 5_c_int32_t
  if (iand(permission_mask, 2_c_int32_t) /= 0_c_int32_t) score = score + 10_c_int32_t
  if (iand(permission_mask, 4_c_int32_t) /= 0_c_int32_t) score = score + 25_c_int32_t
  if (iand(permission_mask, 8_c_int32_t) /= 0_c_int32_t) score = score + 15_c_int32_t
  if (iand(permission_mask, 16_c_int32_t) /= 0_c_int32_t) score = score + 20_c_int32_t
  if (iand(permission_mask, 32_c_int32_t) /= 0_c_int32_t) score = score + 20_c_int32_t

  score = score + min(15_c_int32_t, max(0_c_int32_t, generation) * 2_c_int32_t)
  score = min(100_c_int32_t, score)
end function aurora_capability_risk_score

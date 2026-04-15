pub extern fn aurora_compute_timeslice(run_queue_depth: c_int, base_slice: c_int) c_int;

pub fn computeTimeslice(run_queue_depth: usize, base_slice: usize) usize {
    const depth: c_int = @intCast(run_queue_depth);
    const base: c_int = @intCast(base_slice);
    return @intCast(aurora_compute_timeslice(depth, base));
}

#trap_1site.i 

trap_density = '${fparse 1e3 * surface_concentration_metal_outer}' 
trapping_prefactor = 1e15 
release_prefactor = 1e13 
detrapping_energy = 10000 
trapping_fraction = 0.1 
trap_per_free = 1e3 

[Variables] 
  [c_trapped] 
    block = 2 
    initial_condition = 0 
  [] 
[] 

[AuxVariables] 
  [bounds_dummy_c_trapped] 
    order = FIRST 
    family = LAGRANGE 
    block = 2 
  [] 
[] 

[Bounds] 
  [c_trapped_lower_bound] 
    type = ConstantBounds 
    variable = bounds_dummy_c_trapped 
    bounded_variable = c_trapped 
    bound_type = lower 
    bound_value = 0.0 
  [] 
[] 

[Kernels] 
  [coupled_time_trapped_metal] 
    type = ScaledCoupledTimeDerivative 
    variable = c_metal 
    v = c_trapped 
    factor = ${trap_per_free} 
    block = 2 
    extra_vector_tags = ref 
  [] 
[] 

[NodalKernels] 
  [trapped_time] 
    type = TimeDerivativeNodalKernel 
    variable = c_trapped 
    block = 2 
  [] 
  [trapping] 
    type = TrappingNodalKernel 
    variable = c_trapped 
    alpha_t = ${trapping_prefactor} 
    N = '${fparse trap_density / surface_concentration_metal_outer}' 
    Ct0 = ${trapping_fraction} 
    mobile_concentration = c_metal 
    temperature = temperature 
    trap_per_free = ${trap_per_free} 
    block = 2 
    extra_vector_tags = ref 
  [] 
  [release] 
    type = ReleasingNodalKernel 
    variable = c_trapped 
    alpha_r = ${release_prefactor} 
    temperature = temperature 
    detrapping_energy = ${detrapping_energy} 
    block = 2 
  [] 
[] 

[Postprocessors] 
  [total_c_trapped] 
    type = ElementIntegralVariablePostprocessor 
    variable = c_trapped 
    block = 2 
    outputs = csv_scalars 
  [] 
[]
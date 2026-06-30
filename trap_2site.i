#trap_2site.i

alpha_t_2 = 1e6
alpha_r_2 = 1e6 #1/s
detrapping_energy_2 = 2646 #'${fparse 22000 / ${R}}'
trapping_fraction_2 = 1e-7

[Variables]
  [c_trapped_2] #atoms / µm³
    block = 2
    initial_condition = 0
  []
[]
[AuxVariables]
  [bounds_dummy_c_trapped_2]
    order = FIRST
    family = LAGRANGE
    block = 2
  []
  [empty_sites_2]
    block = 2
  []
[]

[AuxKernels]
  [empty_sites_2_aux]
    type = EmptySitesAux
    variable = empty_sites_2
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_2}
    trapped_concentration_variables = c_trapped_2
    block = 2
  []
[]

[Bounds]
  [c_trapped_lower_bound_2]
    type = ConstantBounds
    variable = bounds_dummy_c_trapped_2
    bounded_variable = c_trapped_2
    bound_type = lower
    bound_value = 0.0
  []
[]

[Kernels]
  [coupled_time_trapped_metal_2]
    type = ScaledCoupledTimeDerivative
    variable = c_metal
    v = c_trapped_2
    factor = ${trap_per_free}
    block = 2
    extra_vector_tags = ref
  []
[]

[NodalKernels]
  [trapped_time_2]
    type = TimeDerivativeNodalKernel
    variable = c_trapped_2
    block = 2
  []
  [trapping_2]
    type = TrappingNodalKernel
    variable = c_trapped_2
    alpha_t = ${alpha_t_2}
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_2} #dimensionless
    mobile_concentration = c_metal
    temperature = temperature
    trap_per_free = ${trap_per_free}
    block = 2
    extra_vector_tags = ref
  []
  [release_2]
    type = ReleasingNodalKernel
    variable = c_trapped_2
    alpha_r = ${alpha_r_2}
    temperature = temperature
    detrapping_energy = ${detrapping_energy_2}
    block = 2
    extra_vector_tags = ref
  []
[]

[Postprocessors]
  [total_c_trapped_2]
    type = ElementIntegralVariablePostprocessor
    variable = c_trapped_2
    block = 2
    outputs = csv_scalars
  []
[]

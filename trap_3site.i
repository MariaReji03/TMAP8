#trap_3site.i

detrapping_energy_3 = 3487.898 #'${fparse 29000 / ${R}}'
trapping_fraction_3 = 7.6e-16

[Variables]
  [c_trapped_3] #atoms / µm³
    block = 2
    initial_condition = 0
  []
[]
[AuxVariables]
  [bounds_dummy_c_trapped_3]
    order = FIRST
    family = LAGRANGE
    block = 2
  []
  [empty_sites_3]
    block = 2
  []
[]

[AuxKernels]
  [empty_sites_3_aux]
    type = EmptySitesAux
    variable = empty_sites_3
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_3}
    trapped_concentration_variables = c_trapped_3
    block = 2
  []
[]

[Bounds]
  [c_trapped_lower_bound_3]
    type = ConstantBounds
    variable = bounds_dummy_c_trapped_3
    bounded_variable = c_trapped_3
    bound_type = lower
    bound_value = 0.0
  []
[]

[Kernels]
  [coupled_time_trapped_metal_3]
    type = ScaledCoupledTimeDerivative
    variable = c_metal
    v = c_trapped_3
    factor = ${trap_per_free}
    block = 2
    extra_vector_tags = ref
  []
[]

[NodalKernels]
  [trapped_time_3]
    type = TimeDerivativeNodalKernel
    variable = c_trapped_3
    block = 2
  []
  [trapping_3]
    type = TrappingNodalKernel
    variable = c_trapped_3
    alpha_t = ${alpha}
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_3} #dimensionless
    mobile_concentration = c_metal
    temperature = temperature
    trap_per_free = ${trap_per_free}
    block = 2
    extra_vector_tags = ref
  []
  [release_3]
    type = ReleasingNodalKernel
    variable = c_trapped_3
    alpha_r = ${alpha}
    temperature = temperature
    detrapping_energy = ${detrapping_energy_3}
    block = 2
    extra_vector_tags = ref
  []
[]

[Postprocessors]
  [total_c_trapped_3]
    type = ElementIntegralVariablePostprocessor
    variable = c_trapped_3
    block = 2
    outputs = csv_scalars
  []
[]

#trap_1site.i 

detrapping_energy_1 = 2164.9 #'${fparse 18000 / ${R}}' #J/mol/R = K
trapping_fraction_1 = 1.3e-9

[Variables] 
  [c_trapped_1] #atoms / µm³
    block = 2 
    initial_condition = 0
  [] 
[] 
[AuxVariables] 
  [bounds_dummy_c_trapped_1]
    order = FIRST 
    family = LAGRANGE 
    block = 2 
  [] 
  [empty_sites_1]
    block = 2
  []
  [total_sites]
    block = 2
  []
[] 

[AuxKernels]
  [empty_sites_1_aux]
    type = EmptySitesAux
    variable = empty_sites_1
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_1}
    trapped_concentration_variables = c_trapped_1
    block = 2
  []
  [total_sites]
    variable = total_sites
    type = ParsedAux
    expression = 'c_trapped_1 + empty_sites_1 + c_trapped_2 + empty_sites_2+c_trapped_3 + empty_sites_3'
    coupled_variables = 'c_trapped_1 empty_sites_1 c_trapped_2 empty_sites_2 c_trapped_3 empty_sites_3'
    block = 2
  []
[]

[Bounds] 
  [c_trapped_lower_bound_1]
    type = ConstantBounds 
    variable = bounds_dummy_c_trapped_1
    bounded_variable = c_trapped_1
    bound_type = lower 
    bound_value = 0.0 
  [] 
[] 

[Kernels] 
  [coupled_time_trapped_metal_1]
    type = ScaledCoupledTimeDerivative 
    variable = c_metal 
    v = c_trapped_1
    factor = ${trap_per_free} 
    block = 2 
    extra_vector_tags = ref 
  [] 
[] 

[NodalKernels]
  [trapped_time_1]
    type = TimeDerivativeNodalKernel
    variable = c_trapped_1
    block = 2
  [] 
  [trapping_1]
    type = TrappingNodalKernel
    variable = c_trapped_1
    alpha_t = ${alpha}
    N = '${Number_density}'
    Ct0 = ${trapping_fraction_1} #dimensionless
    mobile_concentration = c_metal
    temperature = temperature
    trap_per_free = ${trap_per_free}
    block = 2
    extra_vector_tags = ref
  []
  [release_1]
    type = ReleasingNodalKernel 
    variable = c_trapped_1
    alpha_r = ${alpha}
    temperature = temperature 
    detrapping_energy = ${detrapping_energy_1}
    block = 2 
    extra_vector_tags = ref
  [] 
[] 

[Postprocessors] 
  [total_c_trapped_1]
    type = ElementIntegralVariablePostprocessor 
    variable = c_trapped_1
    block = 2
    outputs = csv_scalars 
  [] 
[]

[VectorPostprocessors]
  [axial_trap_balance]
    type = LineValueSampler
    variable = 'c_trapped_1 empty_sites_1 c_trapped_2 empty_sites_2 c_trapped_3 empty_sites_3 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${tube_height} 0'
    num_points  = '${num_mesh_elements_across_axis}'
    sort_by = y
    execute_on = final
    outputs = csv_spatial
  []
  [radial_trap_balance_mid]
    type = LineValueSampler
    variable = 'c_trapped_1 empty_sites_1 c_trapped_2 empty_sites_2 c_trapped_3 empty_sites_3 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${units 0.0055 m -> mum} 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${units 0.0055 m -> mum} 0'
    num_points  = '${num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = final
    outputs = csv_spatial
  []
[]
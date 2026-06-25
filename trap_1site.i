#trap_1site.i 

alpha_t = 1e6
alpha_r = '${units 1e6 1/s}'
detrapping_energy = '${units 18000  J/mol}'
trapping_fraction = 1e-6
trap_per_free = 1 #dimensionless
Number_density = '${units 6.99e23 at/cm^3 -> at/mum^3}' # calculated for Pd

[Variables] 
  [c_trapped] #atoms / µm³
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
    Ct0 = ${trapping_fraction}
    trapped_concentration_variables = c_trapped
    block = 2
  []
  [total_sites]
    variable = total_sites
    type = ParsedAux
    expression = 'c_trapped + empty_sites_1'
    coupled_variables = 'c_trapped empty_sites_1'
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
    alpha_t = ${alpha_t}
    N = '${Number_density}'
    Ct0 = ${trapping_fraction} #dimensionless
    mobile_concentration = c_metal 
    temperature = temperature 
    trap_per_free = ${trap_per_free} 
    block = 2 
    extra_vector_tags = ref 
  [] 
  [release] 
    type = ReleasingNodalKernel 
    variable = c_trapped 
    alpha_r = ${alpha_r}
    temperature = temperature 
    detrapping_energy = ${detrapping_energy} 
    block = 2 
    extra_vector_tags = ref
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

[VectorPostprocessors]
  [axial_trap_balance]
    type = LineValueSampler
    variable = 'c_trapped empty_sites_1 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${tube_height} 0'
    num_points  = '${num_mesh_elements_across_axis}'
    sort_by = y
    execute_on = final
    outputs = csv_spatial
  []
  [radial_trap_balance_mid]
    type = LineValueSampler
    variable = 'c_trapped empty_sites_1 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${units 0.0055 m -> mum} 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${units 0.0055 m -> mum} 0'
    num_points  = '${num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = final
    outputs = csv_spatial
  []
[]
metal_thickness = 0.01e-3 # m
outer_diameter =  0.2944e-3 # m
inner_radius = '${fparse outer_diameter/2-metal_thickness}'
tube_height = 0.011 #m
num_mesh_elements_across_metal = 50
num_mesh_elements_across_inner_diameter = 82 
num_mesh_elements_across_axis = 132

initial_temperature = 723.15 # K
outside_pressure = 2.0e5 # Pa
vacuum_pressure = 1e-6 # Pa
R = 8.31446261815324 # ideal gas constant
initial_concentration_vacuum = '${fparse vacuum_pressure/R/initial_temperature}'

metal_solubility_K0 = '${fparse 2 * 4.45e-1}' # the factor 2 is here to convert from mol(Q2)/m3/sqrt(Pa) to mol(Q)/m3/sqrt(Pa)
metal_solubility_Ea = -8.4e3 # J/mol
surface_concentration_metal_outer = '${fparse metal_solubility_K0*exp(-metal_solubility_Ea/R/initial_temperature)*sqrt(outside_pressure)}'

[Mesh]
  coord_type = RZ
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    nx = '${fparse num_mesh_elements_across_inner_diameter + num_mesh_elements_across_metal}'
    ny = '${fparse num_mesh_elements_across_axis}'
    xmin = 0
    xmax = '${fparse inner_radius + metal_thickness}'
    ymin = 0
    ymax = ${tube_height}
  []
  [block1] # vacuum
    type = SubdomainBoundingBoxGenerator
    block_id = 1
    bottom_left = '0 0 0'
    top_right = '${inner_radius} ${tube_height} 0'
    input = gen
  []
  [block2] # metal
    type = SubdomainBoundingBoxGenerator
    block_id = 2
    bottom_left = '${inner_radius} 0 0'
    top_right = '${fparse inner_radius + metal_thickness} ${tube_height} 0'
    input = block1
  []
  [interface_vacuum_to_metal]
    type = SideSetsBetweenSubdomainsGenerator
    input = block2
    primary_block = 1
    paired_block = 2
    new_boundary = 'interface_vacuum_metal'
  []
  [interface_metal_to_vacuum]
    type = SideSetsBetweenSubdomainsGenerator
    input = interface_vacuum_to_metal
    primary_block = 2
    paired_block = 1
    new_boundary = 'interface_metal_vacuum'
  []
  [bottom_vacuum_side]
    type = ParsedGenerateSideset
    input = interface_metal_to_vacuum
    combinatorial_geometry = 'y =0 & x < ${inner_radius}'
    new_sideset_name = 'bottom_vacuum'
    included_subdomains = '1'
  []
  [bottom_metal_side]
    type = ParsedGenerateSideset
    input = bottom_vacuum_side
    combinatorial_geometry = 'y =0 & x >= ${inner_radius}'
    new_sideset_name = 'bottom_metal'
    included_subdomains = '2'
  []
[]

[Problem]
  type = ReferenceResidualProblem
  extra_tag_vectors = 'ref'
  reference_vector = 'ref'
[]

[Variables]
  [c_metal]
    block = 2 # metal
    initial_condition = '${fparse initial_concentration_vacuum}'
  []
  [c_vacuum]
    block = 1 # vacuum
    initial_condition = '${fparse initial_concentration_vacuum}'
  []
[]

[Kernels]
  [timeDerivative_metal]
    type = TimeDerivative
    variable = c_metal
    extra_vector_tags = ref
    block = 2 # metal
  []
  [diffusion_metal]
    type = MatDiffusion
    variable = c_metal
    diffusivity = diffusivity
    extra_vector_tags = ref
    block = 2 # metal
  []
  [timeDerivative_vacuum]
    type = TimeDerivative
    variable = c_vacuum
    extra_vector_tags = ref
    block = 1 # vacuum
  []
  [diffusion_vacuum]
    type = MatDiffusion
    variable = c_vacuum
    diffusivity = diffusivity
    extra_vector_tags = ref
    block = 1 # vacuum
  []
[]

[AuxVariables]
  [temperature]
    initial_condition = ${initial_temperature} # K
  []
  # Used to prevent negative concentrations
  [bounds_dummy_c_metal]
    order = FIRST
    family = LAGRANGE
  []
  [bounds_dummy_c_vacuum]
    order = FIRST
    family = LAGRANGE
  []
[]

[AuxKernels]
  [temperature_constant]
    type = ConstantAux
    variable = temperature
    value = ${initial_temperature} # K
  []
[]

[Bounds]
  # To prevent negative concentrations
  [c_metal_lower_bound]
    type = ConstantBounds
    variable = bounds_dummy_c_metal
    bounded_variable = c_metal
    bound_type = lower
    bound_value = 0.0
  []
  [c_vacuum_lower_bound]
    type = ConstantBounds
    variable = bounds_dummy_c_vacuum
    bounded_variable = c_vacuum
    bound_type = lower
    bound_value = 0.0
  []
[]

[BCs]
  [inner_vacuum]
    type = NeumannBC
    variable = c_vacuum
    value = 0
    boundary = left # centerline
  []
  [outside_metal] # Sieverts law with outside pressure
    type = DirichletBC
    variable = c_metal
    value = '${surface_concentration_metal_outer}'
    boundary = right #outer_metal
  []
  [bottom_vacuum] # Pressure of the vacuum
    type = DirichletBC
    variable = c_vacuum
    boundary = bottom_vacuum
    value = '${initial_concentration_vacuum}'
  []
[]

[InterfaceKernels]
  [interface]
    type = InterfaceSorption
    K0 = ${metal_solubility_K0}
    Ea = ${metal_solubility_Ea}
    n_sorption = 0.5
    diffusivity = diffusivity
    unit_scale = 1
    unit_scale_neighbor = 1
    temperature = temperature
    variable = c_metal
    neighbor_var = c_vacuum
    sorption_penalty = 1e1
    boundary = interface_metal_vacuum
  []
[]

[Materials]
  [constant]
    type = ConstantMaterial
    property_name = 'R'
    value = '8.31446261815324' # ideal gas constant
  []
  [diffusivity_metal]
    type = DerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '2.90e-7 22.2e3'
    material_property_names = 'R'
    expression = 'D0*exp(-Ea/R/temperature)'
    block = 2 # metal
  []
  [diffusivity_vacuum] # 1e8 more than diffusicvity_metal
    type = DerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '2.90e-7 22.2e3'
    material_property_names = 'R'
    expression = '1e8 * D0*exp(-Ea/R/temperature)'
    block = 1 # vacuum
  []
[]

[Postprocessors]
  [flux_vacuum] # verify flux preservation
    type = SideDiffusiveFluxIntegral
    variable = c_vacuum
    boundary = interface_vacuum_metal
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [flux_metal]
    type = SideDiffusiveFluxIntegral
    variable = c_metal
    boundary = right
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [flux_out_bottom]
    type = SideDiffusiveFluxIntegral
    variable = c_vacuum
    boundary = bottom_vacuum
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [total_c_metal]
    type = ElementIntegralVariablePostprocessor
    variable = c_metal
    block = 2
    outputs = csv_scalars
  []
  [total_c_vacuum]
    type = ElementIntegralVariablePostprocessor
    variable = c_vacuum
    block = 1
    outputs = csv_scalars
  []
[]

[VectorPostprocessors]
  [radial_profile_metal_mid]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${inner_radius} 0.0055 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0.0055 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_mid]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0.0055 0'
    end_point   = '${inner_radius} 0.0055 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
    [radial_profile_metal_top]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${inner_radius} 0.011 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0.011 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_top]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0.011 0'
    end_point   = '${inner_radius} 0.011 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
    [radial_profile_metal_bottom]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${inner_radius} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_bottom]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 0'
    end_point   = '${inner_radius} 0 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_metal_inner]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${inner_radius} 0 0'
    end_point   = '${inner_radius} ${tube_height} 0'
    num_points  = 40
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_metal_outer]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${tube_height} 0'
    num_points  = 40
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_vacuum_center]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 0'
    end_point   = '0 ${tube_height} 0'
    num_points  = 40
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
[]

# It converges faster if all the residuals are at the same magnitude
[Debug]
  show_var_residual_norms = true
  #show_top_residuals = 1
[]

[Preconditioning]
  active = Newtonlu
  [Newtonlu]
    type = SMP
    full = true
    solve_type = 'NEWTON'
    petsc_options_iname = '-pc_type -pc_hypre_type -snes_type'
    petsc_options_value = 'hypre boomeramg vinewtonrsls'
  []
[]

[Executioner]
  type = Transient
  line_search = 'none'
  l_tol = 1e-11
  nl_abs_tol = 1e-8 #1e-14
  nl_rel_tol = 1e-5 #1e-08
  l_max_its = 30
  nl_max_its = 20

  end_time = 0.1
  dtmax = 5e-4

  automatic_scaling = true
  compute_scaling_once = false

  # Time Stepper: Using Iteration Adaptative here
  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 6
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.2
    dt = 1e-9 #s
    cutback_factor = 0.5
  []
[]

[Outputs]
  exodus = true
  [csv_scalars]
    type = CSV
    execute_on = 'timestep_end'
  []
  [csv_spatial]
    type = CSV
    execute_on = 'final'
  []
  [dof]
    type = DOFMap
    execute_on = initial
  []
  perf_graph = true
[]

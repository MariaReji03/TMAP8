metal_thickness = '${units 0.01e-3 m -> mum}'
outer_diameter = '${units 0.2944e-3 m -> mum}'
inner_radius = '${fparse outer_diameter/2-metal_thickness}'
tube_height = '${units 0.011 m -> mum}'

num_mesh_elements_across_metal = 20
num_mesh_elements_across_inner_radius = 160
num_mesh_elements_across_axis = 132

initial_temperature = '${units 723.15 K}'
outside_pressure = '${units 2.0e5 Pa}'
HT_mole_fraction = 1.2e-5 #0.0012 mol%
outside_tritium_pressure = '${fparse HT_mole_fraction * outside_pressure}'
vacuum_pressure = '${units 1e-6 Pa}'

R = '${units 8.31446261815324 J/mol/K}'
initial_concentration_vacuum = '${units ${fparse vacuum_pressure/R/initial_temperature} mol/m^3 -> at/mum^3}'

metal_solubility_K0_per_molecule = '${units 4.45e-1 mol/m^3/Pa -> at/mum^3/Pa}'
metal_solubility_K0 = '${fparse 2 * metal_solubility_K0_per_molecule}' # the factor 2 is here to convert from mol(Q2)/m3/sqrt(Pa) to mol(Q)/m3/sqrt(Pa)
metal_solubility_Ea = '${units -8.4e3 J/mol}'
surface_concentration_metal_outer = '${fparse metal_solubility_K0*exp(-metal_solubility_Ea/R/initial_temperature)*sqrt(outside_tritium_pressure)}'

D0_metal = '${units 2.4e-7 m^2/s -> mum^2/s}'
Ea_metal = '${units 21.1e3 J/mol}'

!include trap_1site.i 

[Mesh]
  coord_type = RZ

  [vacuum_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = '${num_mesh_elements_across_inner_radius}'
    ny = '${num_mesh_elements_across_axis}'
    xmin = 0
    xmax = '${inner_radius}'
    ymin = 0
    ymax = '${tube_height}'
    subdomain_ids = 1
  []

  [metal_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = '${num_mesh_elements_across_metal}'
    ny = '${num_mesh_elements_across_axis}'
    xmin = '${inner_radius}'
    xmax = '${fparse inner_radius + metal_thickness}'
    ymin = 0
    ymax = '${tube_height}'
    subdomain_ids = 2
  []

  [stitched]
    type = StitchMeshGenerator
    inputs = 'vacuum_mesh metal_mesh'
    stitch_boundaries_pairs = 'right left'
  []

  [interface_vacuum_to_metal]
    type = SideSetsBetweenSubdomainsGenerator
    input = stitched
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
  [top_metal_side]
    type = ParsedGenerateSideset
    input = bottom_metal_side
    combinatorial_geometry = 'y = ${tube_height} & x >= ${inner_radius}'
    new_sideset_name = 'top_metal'
    included_subdomains = '2'
  []
  [top_vacuum_side]
    type = ParsedGenerateSideset
    input = top_metal_side
    combinatorial_geometry = 'y = ${tube_height} & x < ${inner_radius}'
    new_sideset_name = 'top_vacuum'
    included_subdomains = '1'
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
    type = ADTimeDerivative
    variable = c_metal
    extra_vector_tags = ref
    block = 2 # metal
  []
  [diffusion_metal]
    type = ADMatDiffusion
    variable = c_metal
    diffusivity = diffusivity
    extra_vector_tags = ref
    block = 2 # metal
  []
  [timeDerivative_vacuum]
    type = ADTimeDerivative
    variable = c_vacuum
    extra_vector_tags = ref
    block = 1 # vacuum
  []
  [diffusion_vacuum]
    type = ADMatDiffusion
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
    type = ADNeumannBC
    variable = c_vacuum
    value = 0
    boundary = left # centerline
  []
  [outside_metal] # Sieverts law with outside pressure
    type = ADDirichletBC
    variable = c_metal
    value = '${surface_concentration_metal_outer}'
    boundary = right #outer_metal
  []
  [bottom_vacuum] # Pressure of the vacuum
    type = ADDirichletBC
    variable = c_vacuum
    boundary = bottom_vacuum
    value = '${initial_concentration_vacuum}'
  []
  #Explicitly add NeumannBC on all other boundaries
  [top_vacuum]
    type = ADNeumannBC
    variable = c_vacuum
    value = 0
    boundary = top_vacuum
  []
  [top_metal]
    type = ADNeumannBC
    variable = c_metal
    value = 0
    boundary = top_metal
  []
  [bottom_metal]
    type = ADNeumannBC
    variable = c_metal
    value = 0
    boundary = bottom_metal
  []
[]

[InterfaceKernels]
  [interface]
    type = ADInterfaceSorption
    K0 = ${metal_solubility_K0}
    Ea = ${metal_solubility_Ea}
    n_sorption = 0.5
    diffusivity = diffusivity
    unit_scale = 1
    unit_scale_neighbor = ${fparse ${units 1 m -> mum} ^ 3 / ${units 1 mol -> at}}
    temperature = temperature
    variable = c_metal
    neighbor_var = c_vacuum
    sorption_penalty = 200
    boundary = interface_metal_vacuum
  []
[]

[Materials]
  [diffusivity_metal]
    type = ADDerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '${D0_metal} ${Ea_metal}'
    expression = 'D0*exp(-Ea/${R}/temperature)' 
    block = 2 # metal
  []
  [diffusivity_vacuum] # 1e6 more than diffusivity_metal
    type = ADDerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '${D0_metal} ${Ea_metal}'
    expression = '1e6 * D0*exp(-Ea/${R}/temperature)'
    block = 1 # vacuum
  []
[]

[Postprocessors]
  [flux_vacuum] # verify flux preservation
    type = ADSideDiffusiveFluxIntegral
    variable = c_vacuum
    boundary = interface_vacuum_metal
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [flux_metal]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = right
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [flux_out_bottom]
    type = ADSideDiffusiveFluxIntegral
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
  # interface flux on metal side
  [flux_interface_metal_side]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = interface_metal_vacuum
    diffusivity = diffusivity
    outputs = csv_scalars
  []

  # top boundary fluxes
  [flux_top_metal]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = top_metal
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  [flux_top_vacuum]
    type = ADSideDiffusiveFluxIntegral
    variable = c_vacuum
    boundary = top_vacuum
    diffusivity = diffusivity
    outputs = csv_scalars
  []

  # left boundary (should be zero, just to verify)
  [flux_left_vacuum]
    type = ADSideDiffusiveFluxIntegral
    variable = c_vacuum
    boundary = left
    diffusivity = diffusivity
    outputs = csv_scalars
  []

  # bottom metal (should be zero after sideset split)
  [flux_bottom_metal]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = bottom_metal
    diffusivity = diffusivity
    outputs = csv_scalars
  []
  #mass conservation check
  [flux_metal_cumulative]
    type = TimeIntegratedPostprocessor
    value = flux_metal
    execute_on = 'timestep_end'
    outputs = csv_scalars
  []

  [flux_out_cumulative]
    type = TimeIntegratedPostprocessor
    value = flux_out_bottom
    execute_on = 'timestep_end'
    outputs = csv_scalars
  []
  [flux_top_vacuum_cumulative]
    type = TimeIntegratedPostprocessor
    value = flux_top_vacuum
    execute_on = 'timestep_end'
    outputs = csv_scalars
  []
[]

[VectorPostprocessors]
  [radial_profile_metal_mid]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${units 0.0055 m -> mum} 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${units 0.0055 m -> mum} 0'
    num_points  = '${fparse num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_mid]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 ${units 0.0055 m -> mum} 0'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} ${units 0.0055 m -> mum} 0'
    num_points  = '${fparse num_mesh_elements_across_inner_radius}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_metal_top]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${units 0.011 m -> mum} 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${units 0.011 m -> mum} 0'
    num_points  = '${fparse num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_top]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 ${units 0.011 m -> mum} 0'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} ${units 0.011 m -> mum} 0'
    num_points  = '${fparse num_mesh_elements_across_inner_radius}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_metal_bottom]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0 0'
    num_points  = '${fparse num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_bottom]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 0'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} 0 0'
    num_points  = '${fparse num_mesh_elements_across_inner_radius}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_metal_inner]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} ${tube_height} 0'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_metal_outer]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} ${tube_height} 0'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_vacuum_center]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 0'
    end_point   = '0 ${tube_height} 0'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = y
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_vacuum_outer]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} 0 0'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} ${tube_height} 0'
    num_points  = '${fparse num_mesh_elements_across_axis}'
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

  end_time = 1.75
  dtmax = 5e-3

  automatic_scaling = true
  compute_scaling_once = false

  steady_state_detection = true
  steady_state_tolerance = 1e-3
  steady_state_start_time = 0.01

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

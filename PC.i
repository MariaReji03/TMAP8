metal_thickness = 0.02e-3 # m
outer_diameter = 0.2e-3 # m
inner_radius = '${fparse outer_diameter/2-metal_thickness}'
tube_height = 12.5e-3 #m
num_mesh_elements_across_metal = 6
num_mesh_elements_across_inner_diameter = '${fparse num_mesh_elements_across_metal*4}' # 4 corresponds to inner_radius/metal_thickness
num_mesh_elements_across_axis = '${fparse num_mesh_elements_across_metal*1000}' # 1000 corresponds to tube_height/metal_thickness

initial_temperature = 573.15 # K
outside_pressure = 1e3 # Pa
vaccum_pressure = 1e-6 # Pa
initial_concentration_vaccum = '${fparse vaccum_pressure/R/initial_temperature}'
R = 8.31446261815324 # ideal gas constant
metal_solubility_K0 = '${fparse 2 * 4.45e-1}' # the factor 2 is here to convert from mol(Q2)/m3/sqrt(Pa) to mol(Q)/m3/sqrt(Pa)
metal_solubility_Ea = -8.4e3 # J/mol
surface_concentration_metal_outer = '${fparse metal_solubility_K0*exp(-metal_solubility_Ea/R/initial_temperature)*sqrt(outside_pressure)}'

[Mesh]
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
  [block1] # vaccum
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
  [breakmesh]
    input = block2
    type = BreakMeshByBlockGenerator
    block_pairs = '1 2'
    split_interface = true
    add_interface_on_two_sides = true
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
    initial_condition = '${fparse initial_concentration_vaccum}'
  []
  [c_vaccum]
    block = 1 # vaccum
    initial_condition = '${fparse initial_concentration_vaccum}'
    scaling = 1e1
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
  [timeDerivative_vaccum]
    type = TimeDerivative
    variable = c_vaccum
    extra_vector_tags = ref
    block = 1 # vaccum
  []
  [diffusion_vaccum]
    type = MatDiffusion
    variable = c_vaccum
    diffusivity = diffusivity
    extra_vector_tags = ref
    block = 1 # vaccum
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
  [bounds_dummy_c_vaccum]
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
    type = ConstantBoundsAux
    variable = bounds_dummy_c_metal
    bounded_variable = c_metal
    bound_type = lower
    bound_value = 0.
  []
  [c_vaccum_lower_bound]
    type = ConstantBoundsAux
    variable = bounds_dummy_c_vaccum
    bounded_variable = c_vaccum
    bound_type = lower
    bound_value = 0.
  []
[]

[BCs]
  [inner_vaccum]
    type = NeumannBC
    variable = c_vaccum
    value = 0
    boundary = left # centerline
  []
  [outside_metal] # Sievert's law with outside pressure - expect ~164 mol/m3 for current values
    type = DirichletBC
    variable = c_metal
    value = '${surface_concentration_metal_outer}'
    boundary = right #outer_metal

  []
  [bottom_vaccum] # Pressure of the vaccum
    type = DirichletBC
    variable = c_vaccum
    boundary = bottom
    value = '${initial_concentration_vaccum}'
  []
[]

[InterfaceKernels]
  [interface]
    type = InterfaceSorptionSievert
    K0 = ${metal_solubility_K0}
    Ea = ${metal_solubility_Ea}
    diffusivity = diffusivity
    unit_scale = 1
    unit_scale_neighbor = 1
    temperature = temperature
    variable = c_metal
    neighbor_var = c_vaccum
    sorption_penalty = 1e1
    boundary = Block2_Block1
  []
[]

[Materials]
  [constant]
    type = ConstantMaterial
    property_name = 'R'
    value = '8.31446261815324' # ideal gas constant
  []
  [diffusicvity_metal]
    type = DerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '2.90e-7 22.2e3'
    material_property_names = 'R'
    expression = 'D0*exp(-Ea/R/temperature)'
    block = 2 # metal
  []
  [diffusicvity_vaccum] # 1e8 more than diffusicvity_metal
    type = DerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea'
    constant_expressions = '2.90e-7 22.2e3'
    material_property_names = 'R'
    expression = '1e8 * D0*exp(-Ea/R/temperature)'
    block = 1 # vaccum
  []
[]

[Postprocessors]
  [flux_vaccum] # verify flux preservation
    type = SideDiffusiveFluxIntegral
    variable = c_vaccum
    boundary = Block1_Block2
    diffusivity = diffusivity
    outputs = csv
  []
  [flux_metal]
    type = SideDiffusiveFluxIntegral
    variable = c_metal
    boundary = Block2_Block1
    diffusivity = diffusivity
    outputs = csv
  []
  [total_c_metal]
    type = ElementIntegralVariablePostprocessor
    variable = c_metal
    block = 2
  []
  [total_c_vaccum]
    type = ElementIntegralVariablePostprocessor
    variable = c_vaccum
    block = 1
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
    petsc_options_iname = '-pc_type -sub_pc_type -snes_type'
    petsc_options_value = 'asm      lu           vinewtonrsls' # This petsc option helps prevent negative concentrations'
  []
[]

[Executioner]
  type = Transient
  line_search = 'none'
  l_tol = 1e-11
  nl_abs_tol = 5e-10 #1e-14
  nl_rel_tol = 1e-6 #1e-08
  l_max_its = 20
  nl_max_its = 20

  end_time = 100
  dtmax = 1e0

  # Time Stepper: Using Iteration Adaptative here
  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 12
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.2
    dt = 1e-5 #s
    cutback_factor = 0.75
  []
[]

[Outputs]
  exodus = true
  csv = true
  [dof]
    type = DOFMap
    execute_on = initial
  []
  perf_graph = true
[]

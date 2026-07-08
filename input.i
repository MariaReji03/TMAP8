#input.i

metal_thickness = '${units 0.01e-3 m -> mum}'
outer_diameter = '${units 0.2944e-3 m -> mum}'
inner_radius = '${fparse outer_diameter/2-metal_thickness}'
tube_height = '${units 0.011 m -> mum}'

num_mesh_elements_across_metal = 44
num_mesh_elements_across_inner_radius = 6
num_mesh_elements_across_axis = 57

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
D_K_vacuum = '${units 0.17859 m^2/s -> mum^2/s}'

trap_per_free = 1 #dimensionless
Number_density = '${units 6.8e22 at/cm^3 -> at/mum^3}' # calculated for Pd
alpha = '${units 5.7e12 1/s}'

!include 2D.i
#!include 3D.i
!include trap_1site.i
!include trap_2site.i
!include trap_3site.i

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
    sorption_penalty = 5e3
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
  [diffusivity_vacuum] # from Knudsen diffusion
    type = ADDerivativeParsedMaterial
    property_name = diffusivity
    expression = '${D_K_vacuum}'
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

# It converges faster if all the residuals are at the same magnitude
[Debug]
  show_var_residual_norms = true
  #show_top_residuals = 1
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'
  #l_tol = 1e-11
  nl_abs_tol = 1e-8 #1e-14
  nl_rel_tol = 1e-7 #1e-08
  l_max_its = 30
  nl_max_its = 20

  end_time = 10
  dtmax = 5e-4

  automatic_scaling = true
  compute_scaling_once = true

  steady_state_detection = true
  steady_state_tolerance = 1e-4
  steady_state_start_time = 0.01

  # Time Stepper: Using Iteration Adaptative here
  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 6
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

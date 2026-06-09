# Geometry
metal_thickness = 0.01e-3 # m
outer_diameter = 0.2944e-3 # m
outer_radius = '${fparse outer_diameter / 2}'
inner_radius = '${fparse outer_radius - metal_thickness}'

num_mesh_elements_across_metal = 25

# Conditions
R = 8.31446261815324 #J/ mol K
initial_temperature = 723.15 # K

# Gas pressures
total_pressure_outside = 2.0e5 # Pa
tritium_mole_fraction = 1.2e-5 # example: 0.0012 mol%
outside_tritium_pressure = '${fparse tritium_mole_fraction * total_pressure_outside}'

vacuum_tritium_pressure = 1e-6 # Pa

# Pd solubility, Sieverts law
metal_solubility_K0 = '${fparse 2 * 4.45e-1}'
metal_solubility_Ea = -8.4e3 # J/mol

surface_concentration_metal_outer = '${fparse metal_solubility_K0 * exp(-metal_solubility_Ea / R / initial_temperature) * sqrt(outside_tritium_pressure)}'
surface_concentration_metal_inner = '${fparse metal_solubility_K0 * exp(-metal_solubility_Ea / R / initial_temperature) * sqrt(vacuum_tritium_pressure)}'

[Mesh]
  coord_type = RZ
  rz_coord_axis = Y

  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = ${num_mesh_elements_across_metal}
    xmin = ${inner_radius}
    xmax = ${outer_radius}
  []
[]

[Problem]
  type = ReferenceResidualProblem
  extra_tag_vectors = 'ref'
  reference_vector = 'ref'
[]

[Variables]
  [c_metal]
    initial_condition = ${surface_concentration_metal_inner}
  []
[]

[Kernels]
  [timeDerivative_metal]
    type = TimeDerivative
    variable = c_metal
    extra_vector_tags = ref
  []

  [diffusion_metal]
    type = MatDiffusion
    variable = c_metal
    diffusivity = diffusivity
    extra_vector_tags = ref
  []
[]

[AuxVariables]
  [temperature]
    initial_condition = ${initial_temperature}
  []
[]

[AuxKernels]
  [temperature_constant]
    type = ConstantAux
    variable = temperature
    value = ${initial_temperature}
  []
[]

[BCs]
  [inner_vacuum_surface]
    type = DirichletBC
    variable = c_metal
    boundary = left
    value = ${surface_concentration_metal_inner}
  []

  [outer_gas_surface]
    type = DirichletBC
    variable = c_metal
    boundary = right
    value = ${surface_concentration_metal_outer}
  []
[]

[Materials]
  [constant_R]
    type = ConstantMaterial
    property_name = 'R'
    value = '8.31446261815324'
  []

  [diffusivity_metal]
    type = DerivativeParsedMaterial
    property_name = diffusivity
    coupled_variables = temperature
    constant_names = 'D0 Ea' #m^2/s and J/mol H
    constant_expressions = '2.4e-7 21.1e3'
    material_property_names = 'R'
    expression = 'D0 * exp(-Ea / R / temperature)'
  []
[]

[Postprocessors]
  [flux_inner]
    type = SideDiffusiveFluxIntegral
    variable = c_metal
    boundary = left
    diffusivity = diffusivity
    outputs = csv_scalars 
  []

  [flux_outer]
    type = SideDiffusiveFluxIntegral
    variable = c_metal
    boundary = right
    diffusivity = diffusivity
    outputs = csv_scalars 
  []

  [total_c_metal]
    type = ElementIntegralVariablePostprocessor
    variable = c_metal
    outputs = csv_scalars 
  []
[]

[VectorPostprocessors]
  [radial_profile_metal]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${inner_radius} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0 0'
    num_points  = 20
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
[]

[Debug]
  show_var_residual_norms = true
[]

[Preconditioning]
  active = Newtonlu

  [Newtonlu]
    type = SMP
    full = true
    solve_type = 'NEWTON'
  []
[]

[Executioner]
  type = Transient

  line_search = 'none'
  l_tol = 1e-11
  nl_abs_tol = 5e-10
  nl_rel_tol = 1e-8
  l_max_its = 20
  nl_max_its = 20

  end_time = 1.0
  dtmax = 1e-3

  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 12
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.2
    dt = 1e-5
    cutback_factor = 0.75
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
  perf_graph = true
[]

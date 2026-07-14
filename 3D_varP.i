#3D_varP.i

[Mesh]
  [cross_section]
    type = ConcentricCircleMeshGenerator
    num_sectors = 16
    radii = '${inner_radius} ${fparse inner_radius + metal_thickness}'
    rings = '${num_mesh_elements_across_inner_radius} ${num_mesh_elements_across_metal}'
    has_outer_square = false
    preserve_volumes = true
    portion = full
  []
  [extrude]
    type = AdvancedExtruderGenerator
    input = cross_section
    direction = '0 0 1'
    heights = '${tube_height}'
    num_layers = '${num_mesh_elements_across_axis}'
  []
  [rename_outer_boundary]
    type = RenameBoundaryGenerator
    input = extrude
    old_boundary = 'outer'
    new_boundary = 'outer_metal'
  []
  [rename_blocks]
    type = RenameBlockGenerator
    input = rename_outer_boundary
    old_block = '1 2'
    new_block = '1 2'
  []
  [interface_vacuum_to_metal]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename_blocks
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
  [bottom_vacuum]
    type = ParsedGenerateSideset
    input = interface_metal_to_vacuum
    combinatorial_geometry = 'z < 1e-10 & sqrt(x*x+y*y) < ${inner_radius}'
    new_sideset_name = 'bottom_vacuum'
    included_subdomains = '1'
  []
  [bottom_metal]
    type = ParsedGenerateSideset
    input = bottom_vacuum
    combinatorial_geometry = 'z < 1e-10 & sqrt(x*x+y*y) >= ${inner_radius}'
    new_sideset_name = 'bottom_metal'
    included_subdomains = '2'
  []
  [top_metal]
    type = ParsedGenerateSideset
    input = bottom_metal
    combinatorial_geometry = 'z > ${fparse tube_height - 1e-10} & sqrt(x*x+y*y) >= ${inner_radius}'
    new_sideset_name = 'top_metal'
    included_subdomains = '2'
  []
  [top_vacuum]
    type = ParsedGenerateSideset
    input = top_metal
    combinatorial_geometry = 'z > ${fparse tube_height - 1e-10} & sqrt(x*x+y*y) < ${inner_radius}'
    new_sideset_name = 'top_vacuum'
    included_subdomains = '1'
  []
[]
[Functions]
   # Potential flow solution with only front arc
  [surface_concentration_outer_func]
    type = ParsedFunction
    expression = 'K0*exp(-Ea/R/T)* sqrt(if(x / sqrt(x*x + y*y) > cos(pi/6),p_max * (1 - 4 * y*y / (x*x + y*y)),0))'
    symbol_names = 'K0 Ea R T p_max'
    symbol_values = '${metal_solubility_K0} ${metal_solubility_Ea} ${R} ${initial_temperature} 2.4'
  []
[]

[BCs]
  [outside_metal] # Sieverts law with variable outside pressure
    type = ADFunctionDirichletBC
    variable = c_metal
    boundary = outer_metal
    function = surface_concentration_outer_func
  []
[]

[Postprocessors]
  [flux_metal]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = outer_metal
    diffusivity = diffusivity
    outputs = csv_scalars
  []
[]

[VectorPostprocessors]
  [radial_profile_metal_mid]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius+ metal_thickness/num_mesh_elements_across_metal} 0 ${units 0.0055 m -> mum} '
    end_point   = '${fparse inner_radius + metal_thickness} 0 ${units 0.0055 m -> mum}'
    num_points  = '${fparse num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_mid]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 ${units 0.0055 m -> mum}'
    end_point   = '${fparse inner_radius- inner_radius/num_mesh_elements_across_inner_radius} 0 ${units 0.0055 m -> mum}'
    num_points  = '${fparse num_mesh_elements_across_inner_radius}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_metal_top]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 ${units 0.011 m -> mum}'
    end_point   = '${fparse inner_radius + metal_thickness} 0 ${units 0.011 m -> mum}'
    num_points  = '${fparse num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = 'final'
    outputs = csv_spatial
  []
  [radial_profile_vacuum_top]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 ${units 0.011 m -> mum}'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} 0 ${units 0.011 m -> mum}'
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
    end_point   = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 ${tube_height}'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = z
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_metal_outer]
    type = LineValueSampler
    variable = 'c_metal'
    start_point = '${fparse inner_radius + metal_thickness} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness} 0 ${tube_height}'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = z
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_vacuum_center]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '0 0 0'
    end_point   = '0 0 ${tube_height}'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = z
    execute_on = 'final'
    outputs = csv_spatial
  []
  [axial_profile_vacuum_outer]
    type = LineValueSampler
    variable = 'c_vacuum'
    start_point = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} 0 0'
    end_point   = '${fparse inner_radius - inner_radius/num_mesh_elements_across_inner_radius} 0 ${tube_height}'
    num_points  = '${fparse num_mesh_elements_across_axis}'
    sort_by = z
    execute_on = 'final'
    outputs = csv_spatial
  []

  #Traps
  [axial_trap_balance]
    type = LineValueSampler
    variable = 'c_trapped_1 empty_sites_1 c_trapped_2 empty_sites_2 c_trapped_3 empty_sites_3 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 0'
    end_point   = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 ${tube_height}'
    num_points  = '${num_mesh_elements_across_axis}'
    sort_by = z
    execute_on = final
    outputs = csv_spatial
  []
  [radial_trap_balance_mid]
    type = LineValueSampler
    variable = 'c_trapped_1 empty_sites_1 c_trapped_2 empty_sites_2 c_trapped_3 empty_sites_3 total_sites'
    start_point = '${fparse inner_radius + metal_thickness/num_mesh_elements_across_metal} 0 ${units 0.0055 m -> mum}'
    end_point   = '${fparse inner_radius + metal_thickness} 0 ${units 0.0055 m -> mum}'
    num_points  = '${num_mesh_elements_across_metal}'
    sort_by = x
    execute_on = final
    outputs = csv_spatial
  []
[]

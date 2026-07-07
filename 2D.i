#2D.i

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
[]

[Postprocessors]
  [flux_metal]
    type = ADSideDiffusiveFluxIntegral
    variable = c_metal
    boundary = right
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

  #Traps
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

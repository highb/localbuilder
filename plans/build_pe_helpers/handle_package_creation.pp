plan localbuilder::build_pe_helpers::handle_package_creation(
  String $platform,
  String $version,
  String $vanagon_project,
  Hash $local_vanagon_components,
  Hash $vanagon_component_prs,
) {
  $local_changes = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_vanagon_components).first().value()['changes_present']
  $pr_changes = run_task(localbuilder::check_parameters, localhost, parameters_hash => $vanagon_component_prs).first().value()['changes_present']

   if $local_changes and $pr_changes {
     run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => $vanagon_project, local_vanagon_components=> $local_vanagon_components, vanagon_component_prs => $vanagon_component_prs)
   }
   elsif $local_changes {
     run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => $vanagon_project, local_vanagon_components=> $local_vanagon_components)
   }
   elsif $pr_changes {
     run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => $vanagon_project, vanagon_component_prs => $vanagon_component_prs)
   }
}

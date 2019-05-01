plan localbuilder::build_pe(
  String $platform = 'el-7-x86_64',
  String $version = 'kearney',
#####################################
# pe-backup-tools package parameters
#####################################
  Optional[String] $pe_backup_tools = undef,
  Optional[String] $pe_backup_tools_pr = undef,
#####################################
# pe-installer package parameters
#####################################
  Optional[String] $enterprise_tasks = undef,
  Optional[String] $enterprise_tasks_pr = undef,
  Optional[String] $higgs = undef,
  Optional[String] $higgs_pr = undef,
#####################################
# pe-modules package parameters
#####################################
  Optional[String] $puppet_enterprise_modules = undef,
  Optional[String] $puppet_enterprise_modules_pr = undef,
  Optional[String] $pe_r10k = undef,
  Optional[String] $pe_r10k_pr = undef,
  Optional[String] $pe_razor = undef,
  Optional[String] $pe_razor_pr = undef,
  Optional[String] $pe_support_script = undef,
  Optional[String] $pe_support_script_pr = undef,
#####################################
# pe-task package parameters
#####################################
  Optional[String] $facter_task = undef,
  Optional[String] $facter_task_pr = undef,
  Optional[String] $package = undef,
  Optional[String] $package_pr = undef,
  Optional[String] $puppet_conf = undef,
  Optional[String] $puppet_conf_pr = undef,
  Optional[String] $pe_installer_cd4pe = undef,
  Optional[String] $pe_installer_cd4pe_pr = undef,
  Optional[String] $service = undef,
  Optional[String] $service_pr = undef,
) {
  run_task(localbuilder::localbuilder_setup, localhost)

######################################
# Build pe-modules if changes provided
######################################
  $local_pe_modules_params = { 'puppet-enterprise-modules' => $puppet_enterprise_modules, 'puppetlabs-pe_r10k' => $pe_r10k, 'puppetlabs-pe_razor' => $pe_razor, 'puppetlabs-pe_support_script' => $pe_support_script }
  $pe_modules_pr_params = { 'puppet_enterprise_modules' => $puppet_enterprise_modules_pr, 'puppetlabs-pe_r10k' => $pe_r10k_pr, 'puppetlabs-pe_razor' => $pe_razor_pr, 'puppetlabs-pe_support_script' => $pe_support_script_pr }

  $local_changes_modules = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_pe_modules_params).first().value()['changes_present']
  $pr_changes_modules = run_task(localbuilder::check_parameters, localhost, parameters_hash => $pe_modules_pr_params).first().value()['changes_present']

  if $local_changes_modules and $pr_changes_modules {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-modules-vanagon', local_vanagon_components=> $local_pe_modules_params, vanagon_component_prs => $pe_modules_pr_params)
  }
  elsif $local_changes_modules {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-modules-vanagon', local_vanagon_components => $local_pe_modules_params)
  }
  elsif $pr_changes_modules {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-modules-vanagon', vanagon_component_prs => $pe_modules_pr_params)
  }

########################################
# Build pe-installer if changes provided
########################################
  $local_pe_installer_params = { 'enterprise_tasks' => $enterprise_tasks, 'higgs' => $higgs }
  $pe_installer_pr_params = { 'enterprise_tasks' => $enterprise_tasks_pr, 'higgs' => $higgs_pr }

  $local_changes_installer = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_pe_installer_params).first().value()['changes_present']
  $pr_changes_installer = run_task(localbuilder::check_parameters, localhost, parameters_hash => $pe_installer_pr_params).first().value()['changes_present']

  if $local_changes_installer and $pr_changes_installer {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-installer-vanagon', local_vanagon_components => $local_pe_installer_params, vanagon_component_prs => $pe_installer_pr_params)
  }
  elsif $local_changes_installer {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-installer-vanagon', local_vanagon_components => $local_pe_installer_params)
  }
  elsif $pr_changes_installer {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-installer-vanagon', vanagon_component_prs => $pe_installer_pr_params)
  }

###########################################
# Build pe-backup-tools if changes provided
###########################################
  $local_pe_backup_tools_params = { 'pe-backup-tools' => $pe_backup_tools }
  $pe_backup_tools_pr_params = { 'pe-backup-tools' => $pe_backup_tools_pr }

  $local_changes_backup_tools = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_pe_backup_tools_params).first().value()['changes_present']
  $pr_changes_backup_tools = run_task(localbuilder::check_parameters, localhost, parameters_hash => $pe_backup_tools_pr_params).first().value()['changes_present']

  if $local_changes_backup_tools and $pr_changes_backup_tools {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-backup-tools-vanagon', local_vanagon_components => $local_pe_backup_tools_params, vanagon_component_prs => $pe_backup_tools_pr_params)
  }
  elsif $local_changes_backup_tools {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-backup-tools-vanagon', local_vanagon_components => $local_pe_backup_tools_params)
  }
  elsif $pr_changes_backup_tools {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-backup-tools-vanagon', vanagon_component_prs => $pe_backup_tools_pr_params)
  }

####################################
# Build pe-tasks if changes provided
####################################
  $local_pe_tasks_params = { 'puppetlabs-facter_task' => $facter_task, 'puppetlabs-package' => $package, 'puppetlabs-puppet_conf' => $puppet_conf, 'puppetlabs-pe_installer_cd4pe' => $pe_installer_cd4pe, 'puppetlabs-service' => $service }
  $pe_tasks_pr_params = { 'puppetlabs-facter_task' => $facter_task_pr, 'puppetlabs-package' => $package_pr, 'puppetlabs-puppet_conf' => $puppet_conf_pr, 'puppetlabs-pe_installer_cd4pe' => $pe_installer_cd4pe_pr, 'puppetlabs-service' => $service_pr }

  $local_changes_tasks = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_pe_installer_params).first().value()['changes_present']
  $pr_changes_tasks = run_task(localbuilder::check_parameters, localhost, parameters_hash => $pe_installer_pr_params).first().value()['changes_present']

  if $local_changes_tasks and $pr_changes_tasks {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-tasks', local_vanagon_components => $local_pe_tasks_params, vanagon_component_prs => $pe_tasks_pr_params)
  }
  elsif $local_changes_tasks {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-tasks', local_vanagon_components => $local_pe_tasks_params)
  }
  elsif $pr_changes_tasks {
    run_task(localbuilder::build_vanagon_package, localhost, platforms => [$platform], version => $version, vanagon_project => 'pe-tasks', vanagon_component_prs => $pe_tasks_pr_params)
  }
  
########################################
# Provision VM and build PE tarball
########################################
  $vm = run_task(localbuilder::get_floaty_host, localhost, platforms => [$platform]).first().value()['vm_hostnames'][0]
  $tarball_path = run_task(localbuilder::get_pe_build, $vm, version => $version, platform => $platform).first().value()['tarball_path']
  $pe_dir = run_task(localbuilder::expand_pe_tarball, $vm, tarball => $tarball_path).first().value()['pe_dir']
  $packages_list = run_task(localbuilder::get_custom_packages, localhost).first().value()['package_list']
  
  $packages_list.each |String $filename| {
    upload_file("/tmp/localbuilder/packages/${filename}", "${pe_dir}/packages/${platform}/${filename}", $vm)
  }

  run_task(localbuilder::sign_el_packages, $vm, packages => $packages_list, pe_dir => $pe_dir, platform => $platform)

  run_task(localbuilder::cleanup_floaty_host, localhost, hostname => $vm) 
  run_task(localbuilder::localbuilder_cleanup, localhost) 
}

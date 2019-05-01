plan localbuilder::build_pe(
  #String $platform,
  #String $version,
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

  $vm = run_task(localbuilder::get_floaty_host, localhost, platforms => ['el-7-x86_64']).first().value()['vm_hostnames'][0]
  $tarball_path = run_task(localbuilder::get_pe_build, $vm, version => 'kearney', platform => 'el-7-x86_64').first().value()['tarball_path']
  $pe_dir = run_task(localbuilder::expand_pe_tarball, $vm, tarball => $tarball_path).first().value()['pe_dir']

######################################
# Build pe-modules if changes provided
######################################
  $local_pe_modules_params = { 'puppet-enterprise-modules' => $puppet_enterprise_modules, 'puppetlabs-pe_r10k' => $pe_r10k, 'puppetlabs-pe_razor' => $pe_razor, 'puppetlabs-pe_support_script' => $pe_support_script }
  $pe_modules_pr_params = { 'puppet_enterprise_modules' => $puppet_enterprise_modules_pr, 'puppetlabs-pe_r10k' => $pe_r10k_pr, 'puppetlabs-pe_razor' => $pe_razor_pr, 'puppetlabs-pe_support_script' => $pe_support_script_pr }

  $local_changes = run_task(localbuilder::check_parameters, localhost, parameters_hash => $local_pe_modules_params).first().value()['changes_present']
  $pr_changes = run_task(localbuilder::check_parameters, localhost, parameters_hash => $pe_modules_pr_params).first().value()['changes_present']

  if $local_changes {
    run_task(localbuilder::build_pe_modules, localhost, platforms => ['el-7-x86_64'], version => 'kearney', local_pe_modules_components => $local_pe_modules_params)
  }
  elsif $pr_changes {
    run_task(localbuilder::build_pe_modules, localhost, platforms => ['el-7-x86_64'], version => 'kearney', pe_modules_components_prs => $pe_modules_pr_params)
  }
  
  $packages_list = run_task(localbuilder::get_custom_packages, localhost).first().value()['package_list']
  
  $packages_list.each |String $filename| {
    upload_file("/tmp/localbuilder/packages/${filename}", "${pe_dir}/packages/el-7-x86_64/${filename}", $vm)
  }

  run_task(localbuilder::sign_el_packages, $vm, packages => $packages_list, pe_dir => $pe_dir, platform => 'el-7-x86_64')

  run_task(localbuilder::cleanup_floaty_host, localhost, hostname => $vm) 
  run_task(localbuilder::localbuilder_cleanup, localhost) 
}

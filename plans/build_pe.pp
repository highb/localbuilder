plan localbuilder::build_pe(
  $params = nil,
) {
  run_task(localbuilder::localbuilder_setup, localhost)
  $vm = run_task(localbuilder::get_floaty_host, localhost, platforms => ['el-7-x86_64']).first().value()['vm_hostnames'][0]
  $tarball_path = run_task(localbuilder::get_pe_build, $vm, version => 'kearney', platform => 'el-7-x86_64').first().value()['tarball_path']
  $pe_dir = run_task(localbuilder::expand_pe_tarball, $vm, tarball => $tarball_path).first().value()['pe_dir']

  $packages_list = run_task(localbuilder::get_custom_packages, localhost).first().value()['package_list']
  
  $packages_list.each |String $filename| {
    upload_file("/tmp/localbuilder/packages/${filename}", "${pe_dir}/packages/el-7-x86_64/${filename}", $vm)
  }

  run_task(localbuilder::sign_el_packages, $vm, packages => $packages_list, pe_dir => $pe_dir, platform => 'el-7-x86_64')

  #run_task(localbuilder::cleanup_floaty_host, localhost, hostname => $vm) 
  #run_task(localbuilder::localbuilder_cleanup, localhost) 
}

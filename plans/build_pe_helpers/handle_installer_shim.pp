plan localbuilder::build_pe_helpers::handle_installer_shim(
  TargetSpec $host,
  String $pe_dir,
  String $version,
  Optional[String] $local_installer_shim,
  Optional[String] $installer_shim_prs,
) {
   $result = run_task(localbuilder::build_installer_shim, localhost, version => $version, local_installer_shim => $local_installer_shim, installer_shim_prs => $installer_shim_prs).first().value()
   
   $shim_dir = $result['shim_dir']
   $shim_files = $result['shim_files']

   $shim_files.each |String $filename| {
     upload_file("${shim_dir}/${filename}", "${pe_dir}/${filename}", $host)
   }
}

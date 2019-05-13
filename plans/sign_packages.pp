plan localbuilder::sign_packages(
  Array[String] $packages,
  String $pe_dir,
  String $platform,
  TargetSpec $host,
) {
   if $platform =~ /el/ {
     run_task(localbuilder::sign_el_packages, $host, packages => $packages, pe_dir => $pe_dir, platform => $platform)
   }
   elsif $platform =~ /ubuntu/ {
     run_task(localbuilder::sign_deb_packages, $host, packages => $packages, pe_dir => $pe_dir, platform => $platform)
   }
   elsif $platform =~ /sles/ {
     run_task(localbuilder::sign_sles_packages, $host, packages => $packages, pe_dir => $pe_dir, platform => $platform)
   } 
   else {
     fail_plan("Platform ${platform} does not appear to be a valid PE master platform")
   }
}

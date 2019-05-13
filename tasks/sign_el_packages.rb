#!/usr/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

# Thanks to Joshua Partlow's meep_tools and the existing frankenbuilder script for providing the entire basis for this package signing
# https://github.com/jpartlow/meep_tools/blob/master/tasks/sign_and_update_deb_repo.sh
# The functionality is essentially identical, but I ported the bash script to Ruby, although this
#   mostly ended up being calls to shell commands anyway...
class SignELPackages < TaskHelper
  def task(packages: nil, pe_dir: nil, platform: nil, **kwargs)
    signed = false

    gpg_private = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder"
    gpg_public = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder.pub"

    Open3.capture2e('yum install -y rpm-sign createrepo expect')
    
    output, status = Open3.capture2e("gpg --import #{gpg_private}")
    raise TaskHelper::Error.new("Failed to import GPG private key", 'barr.localbuilder/sign-el-package-failed', output) if !status.exitstatus.zero?

    output, status = Open3.capture2e("rpm --import #{gpg_public}")
    raise TaskHelper::Error.new("Failed to import GPG public key", 'barr.localbuilder/sign-el-package-failed', output) if !status.exitstatus.zero?

    packages.each do |package|
      keyid = ''
      # I stole the frankenbuilder keys, so that's why this looks like this
      if platform =~ /el-6/
        rpmmacros_contents = <<-EOF
%_signature gpg
%_gpg_path /root/.gnupg
%_gpg_name Frankenbuilder Signing Key <team-organizational-scale@puppet.com>
%_gpgbin /usr/bin/gpg
    EOF
        File.write('/root/.rpmmacros', rpmmacros_contents)
      else
        keyid = "--key-id frankenbuilder"
      end

      package_location = "#{pe_dir}/packages/#{platform}/#{package}"
      file_contents = <<-EOF
#!/usr/bin/expect -f
spawn rpmsign #{keyid} --addsign #{package_location}
expect "Enter pass phrase:"
send "\\r"
expect "Pass phrase is good."
expect "#{package_location}:"
expect eof
    EOF

      File.write('rpmsign.expect', file_contents)
      output, status = Open3.capture2e('expect -d rpmsign.expect')
      raise TaskHelper::Error.new("Failed to sign package: #{package}", 'barr.localbuilder/sign-el-package-failed', output) if !status.exitstatus.zero?

      output, status = Open3.capture2e("rpm -K #{package_location} | grep 'pgp'")
      raise TaskHelper::Error.new("Failed to sign package: #{package}", 'barr.localbuilder/sign-el-package-failed', output) if !status.exitstatus.zero?
    end
    signed = true

    output, status = Open3.capture2e("createrepo #{pe_dir}/packages/#{platform}")
    raise TaskHelper::Error.new("createrepo call failed in this directory: #{pe_dir}/packages/#{platform}", 'barr.localbuilder/sign-el-package-failed', output) if !status.exitstatus.zero?
    
    result = { signed: signed }
    result.to_json
  end
end

SignELPackages.run if __FILE__ == $PROGRAM_NAME

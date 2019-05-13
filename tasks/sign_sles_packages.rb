#!/usr/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'
require 'digest'

# Thanks to Joshua Partlow's meep_tools for providing the entire basis for this package signing on Sles
# https://github.com/jpartlow/meep_tools/blob/master/tasks/sign_and_update_sles_repo.sh
# The functionality is essentially identical, but I ported the bash script to Ruby, although this 
#   mostly ended up being calls to shell commands anyway...

class SignSlesPackages < TaskHelper
  def task(pe_dir: nil, platform: nil, **kwargs)
    signed = false

    gpg_private = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder"
    gpg_public = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder.pub"
    package_dir = "#{pe_dir}/packages/#{platform}"

    Open3.capture2e('zypper install -y createrepo')
   
    # Import public/private GPG keys
    output, status = Open3.capture2e("gpg --import #{gpg_private}")
    raise TaskHelper::Error.new("Failed to import GPG private key", 'barr.localbuilder/sign-sles-package-failed', output) if !status.exitstatus.zero?

    output, status = Open3.capture2e("rpm --import #{gpg_public}")
    raise TaskHelper::Error.new("Failed to import GPG public key", 'barr.localbuilder/sign-sles-package-failed', output) if !status.exitstatus.zero?


    output, status = Open3.capture2e("createrepo #{package_dir}")
    raise TaskHelper::Error.new("Failed to call createrepo", 'barr.localbuilder/sign-sles-package-failed', output) if !status.exitstatus.zero?

    # Remove old repodata file
    output, status = Open3.capture2e("rm -f #{package_dir}/repodata/repomd.xml.asc")
    raise TaskHelper::Error.new("Failed to remove package artifacts", 'barr.localbuilder/sign-sles-package-failed', output) if !status.exitstatus.zero?

    # Sign packages
    output, status = Open3.capture2e("gpg --detach-sign --armor --force-v3-sigs \"#{package_dir}/repodata/repodata.xml\"")
    raise TaskHelper::Error.new("Failed to remove package artifacts", 'barr.localbuilder/sign-sles-package-failed', output) if !status.exitstatus.zero?

    result = true
    result = { signed: signed }
    result.to_json
  end
end

SignSlesPackages.run if __FILE__ == $PROGRAM_NAME

#!/usr/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'
require 'digest'

# Thanks to Joshua Partlow's meep_tools for providing the entire basis for this package signing on Debian
# https://github.com/jpartlow/meep_tools/blob/master/tasks/sign_and_update_deb_repo.sh
# The functionality is essentially identical, but I ported the bash script to Ruby, although this 
#   mostly ended up being calls to shell commands anyway...

class SignDebPackages < TaskHelper
  def get_md5(package)
    Digest::MD5.hexdigest(File.read(package))
  end

  def get_bytes(package)
    File.size(package)
  end

  def get_sha256(package)
    Digest::SHA256.hexdigest(File.read(package))
  end

  def task(pe_dir: nil, platform: nil, **kwargs)
    signed = false

    gpg_private = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder"
    gpg_public = "#{kwargs[:_installdir]}/localbuilder/files/GPG-KEY-localbuilder.pub"
    package_dir = "#{pe_dir}/packages/#{platform}"
    debian_codename = Open3.capture2e('lsb_release -c')[0]

    # Slice returns the thing it sliced, which is great...
    debian_codename.slice!('Codename:')
    debian_codename = debian_codename.strip

    Open3.capture2e('apt update && apt install -y dpkg-dev')
   
    # Import public/private GPG keys
    output, status = Open3.capture2e("gpg --import #{gpg_private}")
    raise TaskHelper::Error.new("Failed to import GPG private key", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?

    output, status = Open3.capture2e("cat #{gpg_public} | apt-key add -")
    raise TaskHelper::Error.new("Failed to import GPG public key", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?

    # Clean up previous Package/Release artifacts from the PE package directory
    # Ruby didn't like me using `rm <filepath>/{multiple_files}` notation to try and bulk remove these files,
    #   so I decided to do it this way for now
    old_release_files = ['Release', 'Release.gpg', 'Packages', 'Packages.gz']
    old_release_files.each do |file|
      output, status = Open3.capture2e("rm #{package_dir}/#{file}")
      raise TaskHelper::Error.new("Failed to remove package artifacts", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?
    end

    # Create new Package and Package.gz
    package_file = package_dir + '/Packages'
    package_archive = package_dir + '/Packages.gz'
    Dir.chdir package_dir do
      output, status = Open3.capture2e("dpkg-scanpackages . /dev/null 1> \"#{package_file}\"")
      raise TaskHelper::Error.new("Failed to create Packages file", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?

      output, status = Open3.capture2e("gzip -9c \"#{package_file}\" > \"#{package_archive}\"")
      raise TaskHelper::Error.new("Failed to zip Packages file into Packages.gz", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?
    end

    release_file_contents = <<-EOF
Origin: Puppetlabs
Codename: #{debian_codename}
Architecture: amd64
MD5Sum:
 #{get_md5(package_archive)} #{get_bytes(package_archive)} Packages.gz
 #{get_md5(package_file)} #{get_bytes(package_file)} Packages
SHA256:
 #{get_sha256(package_archive)} #{get_bytes(package_archive)} Packages.gz
 #{get_sha256(package_file)} #{get_bytes(package_file)} Packages
EOF

    # Create release files
    release_file = package_dir + '/Release'
    release_file_asc = package_dir + '/Release.gpg'

    File.write(release_file, release_file_contents)
    output, status = Open3.capture2e("chmod 644 #{release_file}")
    raise TaskHelper::Error.new("Failed to create release file", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?

    # Sign release file
    output, status = Open3.capture2e("gpg --armor --detach-sign --output #{release_file_asc} #{release_file}")
    raise TaskHelper::Error.new("Failed to create release file", 'barr.localbuilder/sign-deb-package-failed', output) if !status.exitstatus.zero?

    result = true
    result = { signed: signed }
    result.to_json
  end
end

SignDebPackages.run if __FILE__ == $PROGRAM_NAME

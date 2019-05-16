#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/build_vanagon_package_helpers.rb'
require_relative '../lib/pe_version_helpers.rb'
require 'json'
require 'open3'
require 'tmpdir'

class BuildInstallerShim < TaskHelper
  def task(version: nil, local_installer_shim: nil, installer_shim_prs: nil, **kwargs)
    # If the version is passed in as 'x.y' or 'x.y.z', make sure it's git friendly (i.e. 2018.1.x instead of 2018.1 or 2018.1.7)
    # If version is a codename, it remains a codename
    version = PEVersion.convert_to_git_version(version)
    shim_dir = ''


    if installer_shim_prs && installer_shim_prs.include?(',')
      installer_shim_prs = installer_shim_prs.split(',') 
    elsif installer_shim_prs
      installer_shim_prs = [installer_shim_prs]
    end
    
    shim_dir = BuildVanagonPackageHelpers::get_local_pwd(local_installer_shim) if local_installer_shim
    shim_files = ['puppet-enterprise-installer', 'puppet-enterprise-uninstaller', 'locales', 'conf.d', 'links']

    output = ''
    Dir.chdir '/tmp/localbuilder/installer-shim-files' do
      # Uses PR changes if both local and PR changes are specified
      # TODO: Use both?
      if installer_shim_prs
        BuildVanagonPackageHelpers::merge_pr('pe-installer-shim', installer_shim_prs, version)
        shim_dir = "#{Dir.pwd}/pe-installer-shim"
      end
    end

    result = { shim_files: shim_files, shim_dir: shim_dir }
    result.to_json
  end
end

BuildInstallerShim.run if __FILE__ == $PROGRAM_NAME

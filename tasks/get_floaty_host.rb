#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class GetFloatyHost < TaskHelper
  def generate_floaty_platform_string(platform)
    # centos handling for now
    # to get rhel, pass in redhat-... specifically
    case platform
    when /el-/
      # el platform strings should look like el-<version>-x86_64
      #   if they're well-formatted
      # That'll lead to this super-great(tm) split working:
      el_version = platform.split('-')[1]
      "centos-#{el_version}-x86_64"
    when /ubuntu/
      # ubuntu platform strings should also be ubuntu-<version>-...
      # also, if the version is passed in with a '.', that should be deleted for vmpooler platform names 
      ubuntu_version = platform.split('-')[1].delete('.')
      "ubuntu-#{ubuntu_version}-x86_64"
    else
      # I _think_ some platform strings shouldn't need any modification
      platform
    end
  end

  def task(platforms: nil, **kwargs)
    vm_hostnames = []
    platforms.each do |platform|
      platform = generate_floaty_platform_string(platform)
      output, status = Open3.capture2e("floaty get #{platform}")

      # Grabs just the hostname from the floaty output
      hostname = output.split(' ')[1]
      vm_hostnames.push(hostname)
    end

    result = { vm_hostnames: vm_hostnames }
    result.to_json
  end
end

GetFloatyHost.run if __FILE__ == $PROGRAM_NAME

#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/build_vanagon_package_helpers.rb'
require 'open3'

class DownloadCustomPEBuild < TaskHelper
  def task(vm: nil, tarball_path: nil, output_dir: nil, **_kwargs)
    _, status = Open3.capture2e("test -e #{output_dir}")
   
    if !status.exitstatus.zero? && output_dir == 'builds/'
      # Create localbuilder/builds directory
      Open3.capture2e("mkdir -p #{output_dir}")if !status.exitstatus.zero?
    elsif !status.exitstatus.zero?
      raise TaskHelper::Error.new("#{output_dir} does not seem to exist; please provide a valid output directory", 'barr.localbuilder/download-custom-pe-build-failed', output)
    end

    output, status = Open3.capture2e("scp root@#{vm}:#{tarball_path} #{output_dir}")
    raise TaskHelper::Error.new("Could not download custom PE build from #{vm}:#{tarball_path} to #{output_dir}", 'barr.localbuilder/download-custom-pe-build-failed', output) if !status.exitstatus.zero?

    tarball_name = tarball_path.split('/').last

    # Create absolute path to PE tarball to output to user
    # output_dir may already be an abspath, but this won't hurt to do even in that case
    output_dir = BuildVanagonPackageHelpers.get_local_pwd(output_dir)
    local_tarball_path = output_dir + '/' + tarball_name

    result = { local_tarball_path: local_tarball_path }
    result.to_json
  end
end

DownloadCustomPEBuild.run if __FILE__ == $PROGRAM_NAME

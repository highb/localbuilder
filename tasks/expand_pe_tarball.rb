#!/usr/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/pe_version_helpers.rb'
require 'open3'
require 'tmpdir'

class ExpandPETarball < TaskHelper
  def task(tarball: nil, **_kwargs)
    output, status = Open3.capture2e("tar -xvf #{tarball}")
    raise TaskHelper::Error.new("Could not expand tarball at #{tarball}", 'barr.localbuilder/expand-pe-tarball-failed', output) if !status.exitstatus.zero?

    dir_path = tarball.chomp('.tar')
    result = { pe_dir: dir_path }
    result.to_json
  end
end

ExpandPETarball.run if __FILE__ == $PROGRAM_NAME

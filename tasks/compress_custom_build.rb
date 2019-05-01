#!/usr/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class CompressCustomBuild < TaskHelper
  def task(directory_path: nil, **_kwargs)
    # Weird array handling so that we only compress the PE dir
    dir_array = directory_path.split('/')
    pe_dir = dir_array.pop
    tarball_name = pe_dir + '.tar'
    parent_dir = dir_array.join('/')

    Dir.chdir parent_dir do
      output, status = Open3.capture2e("tar -czf #{tarball_name} #{pe_dir}")
    end

    tarball_path = directory_path.concat('.tar')
    result = { tarball_path: tarball_path }
    result.to_json
  end
end

CompressCustomBuild.run if __FILE__ == $PROGRAM_NAME

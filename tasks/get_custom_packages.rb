#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class GetCustomPackages < TaskHelper
  def task(_)
    package_list = []

    package_filepaths = Dir['/tmp/localbuilder/packages/*']
    package_filepaths.each do |path|
      package_name = path.split('/').last
      package_list.push(package_name)
    end
      
    result = { package_list: package_list }
    result.to_json
  end
end

GetCustomPackages.run if __FILE__ == $PROGRAM_NAME

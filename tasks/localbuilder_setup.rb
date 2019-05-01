#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class LocalbuilderSetup < TaskHelper
  def task(_)
    _, status = Open3.capture2e('test -e /tmp/localbuilder')
    if status.exitstatus.zero?
      # Clear out packages from the last localbuilder run
      Open3.capture2e('rm -rf /tmp/localbuilder/packages/*')
    else
      Open3.capture2e('mkdir -p /tmp/localbuilder/packages') 
    end
  end
end

LocalbuilderSetup.run if __FILE__ == $PROGRAM_NAME

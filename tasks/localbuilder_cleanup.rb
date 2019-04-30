#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class LocalbuilderCleanup < TaskHelper
  def task(_)
    Open3.capture2e('rm -rf /tmp/localbuilder') 
  end
end

LocalbuilderCleanup.run if __FILE__ == $PROGRAM_NAME

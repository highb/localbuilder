#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class LocalbuilderSetup < TaskHelper
  def task(_)
    Open3.capture2e('mkdir /tmp/localbuilder') 
    Open3.capture2e('mkdir /tmp/localbuilder/packages') 
  end
end

LocalbuilderSetup.run if __FILE__ == $PROGRAM_NAME

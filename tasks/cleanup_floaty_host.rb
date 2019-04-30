#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class CleanupFloatyHost < TaskHelper
  def task(hostname: nil, **kwargs)
    Open3.capture2e("floaty delete #{hostname}")
  end
end

CleanupFloatyHost.run if __FILE__ == $PROGRAM_NAME

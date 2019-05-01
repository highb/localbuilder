#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'open3'

class CheckParameters < TaskHelper
  def task(parameters_hash: nil, **kwargs)
    changes_present = false
    parameters_hash.each do |k,v|
      changes_present = true if v != 'undef'
    end
    result = { changes_present: changes_present }
    result.to_json
  end
end

CheckParameters.run if __FILE__ == $PROGRAM_NAME

require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/workloads_collector_add.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

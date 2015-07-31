#
# Cookbook Name:: postgresql-bdr-cluster
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'chef-provisioning-aws-helper::default'

# # Pre-create the machines in parallel
# machine_batch 'precreate' do
#   action [:converge]
#
#   node['postgresql-bdr-cluster']['cluster_nodes'].each do |vmname|
#     machine vmname do
#       recipe 'postgresql-bdr-cluster::aws_instance_setup'
#       machine_options aws_options(vmname)
#     end
#   end
# end

# do Postgres setup sequentially
node['postgresql-bdr-cluster']['cluster_nodes'].each do |vmname|
  machine vmname do
    machine_options aws_options(vmname)
    attribute 'postgresql-bdr-cluster', { use_interface: 'eth0' }
    recipe 'postgresql-bdr-cluster::aws_instance_setup'
    recipe 'postgresql-bdr-cluster::default'
  end
end

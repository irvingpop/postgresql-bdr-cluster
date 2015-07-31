#
# Cookbook Name:: postgresql-bdr-cluster
# Recipe:: rolling_rebuild
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'chef-provisioning-aws-helper::default'

node['postgresql-bdr-cluster']['cluster_nodes'].each do |vmname|
  # TODO: test this, perform for each database, add waits?
  machine_execute "#{vmname} leaves the cluster" do
    machine vmname
    command %Q(sudo -u postgres /usr/pgsql-9.4/bin/psql opscode_chef -c "SELECT bdr.bdr_part_by_node_names(ARRAY['#{vmname}']);")
  end

  ruby_block "#{vmname} leaves: cluster settle for 60 seconds" do
    block do
      sleep 60
    end
  end

  machine vmname do
    action :destroy
  end

  machine vmname do
    recipe 'postgresql-bdr-cluster::default'
    attribute 'postgresql-bdr-cluster', { use_interface: 'eth0' }
    machine_options aws_options(vmname)
  end
end

#
# Cookbook Name:: postgresql-bdr-cluster
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# first, populate /etc/hosts from search results
def extract_cluster_ip(node_results)
  use_interface = node['postgresql-bdr-cluster']['use_interface']
  node_results['network_interfaces'][use_interface]['addresses']
    .select { |k,v| v['family'] == 'inet' }.keys
end

def get_my_cluster_ip
  use_interface = node['postgresql-bdr-cluster']['use_interface']
  node['network']['interfaces'][use_interface]['addresses']
    .select { |k,v| v['family'] == 'inet' }
    .keys
    .first
end
my_cluster_ip = get_my_cluster_ip

found_nodes = search(:node, "name:postgresql-*",
  filter_result: {
    'name' => [ 'name' ],
    'fqdn' => [ 'fqdn' ],
    'network_interfaces' => [ 'network', 'interfaces' ]
  }
).reject { |nodedata| nodedata['network_interfaces'].nil? } #not if no interface data
  .reject { |nodedata| nodedata['name'] == node.name } # not if it's me

found_nodes.each do |nodedata|
  hostsfile_entry extract_cluster_ip(nodedata) do
    hostname nodedata['fqdn']
    aliases [ nodedata['name'] ]
    unique true
    comment 'Chef postgresql-bdr-cluster cookbook'
  end
end

# install and setup Postgres 9.4 BDR
postgres_bin_dir = '/usr/pgsql-9.4/bin'
postgres_data_dir = '/var/lib/pgsql/9.4-bdr/data'

include_recipe 'yum-2ndquadrant::default'

package 'postgresql-bdr94-bdr' do
 action :install
end

execute 'postgres initdb' do
  command "#{postgres_bin_dir}/postgresql94-setup initdb"
  action :run
  not_if "test -f #{postgres_data_dir}/PG_VERSION"
end

template "#{postgres_data_dir}/postgresql.conf" do
  source 'postgresql.conf.erb'
  owner 'postgres'
  group 'postgres'
  mode 0600
  notifies :restart, 'service[postgresql-9.4]'
end

template "#{postgres_data_dir}/pg_hba.conf" do
  source 'pg_hba.conf.erb'
  owner 'postgres'
  group 'postgres'
  mode 00600
  notifies :restart, 'service[postgresql-9.4]'
end

service 'postgresql-9.4' do
  supports :restart => true, :status => true, :reload => true
  action [ :enable, :start ]
end

# Configure databases for replication

node['postgresql-bdr-cluster']['bdr_dbnames'].each do |dbname|
  execute "create_db_#{dbname}" do
    command "#{postgres_bin_dir}/createdb -U postgres #{dbname}"
    action :run
    user 'postgres'
    not_if "#{postgres_bin_dir}/psql postgres -c 'SELECT datname FROM pg_database' |grep #{dbname}"
    notifies :run, "execute[create_extension_btree_gist_#{dbname}]", :immediately
    notifies :run, "execute[create_extension_bdr_#{dbname}]", :immediately
  end

  execute "create_extension_btree_gist_#{dbname}" do
    command "#{postgres_bin_dir}/psql #{dbname} -c 'CREATE EXTENSION IF NOT EXISTS btree_gist'"
    action :nothing
    user 'postgres'
  end

  execute "create_extension_bdr_#{dbname}" do
    command "#{postgres_bin_dir}/psql #{dbname} -c 'CREATE EXTENSION IF NOT EXISTS bdr'"
    action :nothing
    user 'postgres'
  end
end

execute 'create replication user' do
  command %Q(#{postgres_bin_dir}/psql postgres -c "CREATE ROLE replication WITH REPLICATION PASSWORD 'password' SUPERUSER LOGIN")
  user 'postgres'
  action :run
  not_if "#{postgres_bin_dir}/psql postgres -c 'SELECT usename FROM pg_user' |grep replication"
end

# Finally - join the cluster if applicable
if found_nodes.count == 0
  log "I am the first one here, creating BDR group"

  node['postgresql-bdr-cluster']['bdr_dbnames'].each do |dbname|
    execute "bdr_setup_#{node.name}_#{dbname}" do
      command %Q(#{postgres_bin_dir}/psql #{dbname} -c "SELECT bdr.bdr_group_create( local_node_name := '#{node.fqdn}', node_external_dsn := 'host=#{my_cluster_ip} dbname=#{dbname} password=password user=replication' )")
      user 'postgres'
      not_if "#{postgres_bin_dir}/psql #{dbname} -c 'SELECT node_name FROM bdr.bdr_nodes' |grep #{node.fqdn}"
      notifies :run, "execute[bdr_wait_#{node.name}_#{dbname}]", :immediately
    end
  end
else
  pick_a_node = found_nodes.sample # pick one at random, not me
  log "Joining the Postgres cluster, talking to #{pick_a_node['fqdn']}"

  node['postgresql-bdr-cluster']['bdr_dbnames'].each do |dbname|
    execute "bdr_join_#{node.name}_#{dbname}" do
      command %Q(#{postgres_bin_dir}/psql #{dbname} -c "SELECT bdr.bdr_group_join( local_node_name := '#{node.fqdn}', node_external_dsn := 'host=#{my_cluster_ip} dbname=#{dbname} password=password user=replication', join_using_dsn := 'host=#{pick_a_node['fqdn']} dbname=#{dbname} password=password user=replication' )")
      user 'postgres'
      not_if "#{postgres_bin_dir}/psql #{dbname} -c 'SELECT node_name FROM bdr.bdr_nodes' |grep #{node.fqdn}"
      notifies :run, "execute[bdr_wait_#{node.name}_#{dbname}]", :immediately
    end
  end
end

node['postgresql-bdr-cluster']['bdr_dbnames'].each do |dbname|
  execute "bdr_wait_#{node.name}_#{dbname}" do
    command "#{postgres_bin_dir}/psql #{dbname} -c 'SELECT bdr.bdr_node_join_wait_for_ready();'"
    user 'postgres'
    action :nothing
  end
end

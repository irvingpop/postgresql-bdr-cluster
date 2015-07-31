hostsfile_entry node['ipaddress'] do
  hostname node.name
  not_if "grep #{node.name} /etc/hosts"
end

ec2_ephemeral_mount '/var/lib/pgsql' do
  mount_point '/var/lib/pgsql'
end

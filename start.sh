#!/bin/bash

# Heavily copied from vpetersson/docker-puppetmaster
# Thank you :)
#

function initiate_instance {
  echo "Starting node initiation..."

  # Fire up regular Puppet master to generate
  # certificates and folder structure.
  # This shouldn't take more than five seconds.
  echo "Starting Puppet to generate certificates..."
  timeout 5 puppet master --no-daemonize

  echo "Node initation completed..."
}

# Assume that this is a new instance if
# no SSL file for the hostname exist.
if [ ! -f /etc/puppetlabs/puppet/ssl/certs/$(hostname).pem ]; then
  initiate_instance
fi

cat - > /etc/puppetlabs/puppet/puppet.conf <<EOF
[main]
certname = $(hostname)
server = $(hostname)
masterport = 8149
environment = production
runinterval = 1h
basemodulepath = /etc/puppetlabs/code/modules
EOF

if [ -f /master.conf ]; then
	cat /master.conf >> /etc/puppetlabs/puppet/puppet.conf
fi

for CONF in puppetdb.conf hiera.yaml; do
	if [ -f /$CONF ]; then
		cp /$CONF /etc/puppetlabs/puppet/
	fi
done

if [ -f /sysconfig.puppetserver ]; then
	cp /sysconfig.puppetserver /etc/sysconfig/puppetserver
fi

if [ ! -d /etc/puppetlabs/code/environments/production ]; then
	mkdir -p /etc/puppetlabs/code/environments/production
	chown puppet:puppet /etc/puppetlabs/code/environments
fi

if [ ! -d /etc/puppetlabs/puppetserver/conf.d ]; then
	mkdir -p /etc/puppetlabs/puppetserver/conf.d
	chown puppet:puppet /etc/puppetlabs/puppetserver/conf.d
fi

/opt/puppetlabs/bin/puppetserver foreground

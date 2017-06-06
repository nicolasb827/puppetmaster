#!/bin/bash

# Heavily copied from vpetersson/docker-puppetmaster
# Thank you :)
#

AUTOSIGN=$1
ENVIRONMENT=$2
AUTOSIGN_DOMAIN=$3

if [ "1" == "$AUTOSIGN" ]; then
	AUTOSIGN=1
	echo "[master] I am doing autosign"
else
	echo "[master] I am not doing autosign"
	AUTOSIGN=0
fi

if [ "" == "$ENVIRONMENT" ]; then
	ENVIRONMENT="production"
fi
echo "[master] Running with ENV=$ENVIRONMENT"

function initiate_instance {
  echo "[master] Starting node initiation..."

  rm -rf /etc/puppetlabs/puppet/ssl
  mkdir -p /etc/puppetlabs/puppet/ssl
  chown puppet:puppet /etc/puppetlabs/puppet/ssl

  # Fire up regular Puppet master to generate
  # certificates and folder structure.
  # This shouldn't take more than five seconds.
  echo "[master] Starting Puppet to generate certificates... (10 sec)"
  timeout 10 puppet master --no-daemonize

  echo "[master] Node initation completed..."
}

# Assume that this is a new instance if
# no SSL file for the hostname exist.
if [ ! -f /etc/puppetlabs/puppet/ssl/certs/puppetmaster.pem ]; then
  initiate_instance
fi

echo "[master] generating master puppet.conf"
cat - > /etc/puppetlabs/puppet/puppet.conf <<EOF
[main]
certname = puppetmaster
server = puppetmaster
masterport = 8140
environment = $ENVIRONMENT
runinterval = 1h
basemodulepath = /etc/puppetlabs/code/modules
EOF

if [ -f /master.conf ]; then
	echo "[master] adding master.conf to puppet.conf"
	cat /master.conf >> /etc/puppetlabs/puppet/puppet.conf
fi
if [ "1" == "$AUTOSIGN" ]; then
	if [ "" == "$AUTOSIGN_DOMAIN" ]; then
		# append autosign to master conf
		echo "autosign = true" >> /etc/puppetlabs/puppet/puppet.conf
	else
		echo "Should add whitelist to Puppet Conf ... WIP"
		echo "autosign = true" >> /etc/puppetlabs/puppet/puppet.conf
	fi
fi

for CONF in puppetdb.conf hiera.yaml; do
	if [ -f /$CONF ]; then
		echo "[master] copy $CONF to /etc/puppetlabs/puppet/"
		cp /$CONF /etc/puppetlabs/puppet/
	fi
done

if [ -f /sysconfig.puppetserver ]; then
	echo "[master] copy sysconfig(puppet)"
	cp /sysconfig.puppetserver /etc/sysconfig/puppetserver
fi

for D in production dev; do
	if [ ! -d /etc/puppetlabs/code/environments/$D ]; then
		echo "[master] creating directory /etc/puppetlabs/code/environments/$D"
		mkdir -p /etc/puppetlabs/code/environments/$D
	fi
done

if [ ! -d /etc/puppetlabs/code/environments/$ENVIRONMENT ]; then
	echo "[master] finally, creating directory /etc/puppetlabs/code/environments/$ENVIRONMENT"
	mkdir -p /etc/puppetlabs/code/environments/$ENVIRONMENT
fi
echo "[master] copying root repository into production"
rsync -avH /repo/ /etc/puppetlabs/code/environments/production/

echo "[master] changing owner on environment files"
chown -R puppet:puppet /etc/puppetlabs/code/environments

if [ ! -d /etc/puppetlabs/puppetserver/conf.d ]; then
	mkdir -p /etc/puppetlabs/puppetserver/conf.d
	chown puppet:puppet /etc/puppetlabs/puppetserver/conf.d
fi

echo "[master] starting master ..."
/opt/puppetlabs/bin/puppetserver foreground

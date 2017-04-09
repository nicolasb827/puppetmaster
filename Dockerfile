FROM centos:7
MAINTAINER nicolas.belan@gmail.com

VOLUME /var/lib/puppet /etc/puppet/modules /etc/puppet/manifests

RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
RUN yum -y install puppet-server hostname tar

CMD puppet master --verbose --no-daemonize

EXPOSE 8140

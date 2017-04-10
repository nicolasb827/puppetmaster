FROM centos:7
MAINTAINER nicolas.belan@gmail.com

VOLUME /etc/puppetlabs/puppet /etc/puppetlabs/code/modules /etc/puppetlabs/code/environments /etc/puppetlabs/puppet/hieradata 

RUN groupadd puppet
RUN useradd -g puppet puppet
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
RUN yum -y install which hostname tar puppetserver
ADD start.sh /start.sh
ADD puppetserver/auth.conf /etc/puppetlabs/puppetserver/conf.d/auth.conf
ADD puppetserver/master.conf /master.conf
ADD puppetserver/hiera.yaml /hiera.yaml

ENV PATH /opt/puppetlabs/bin/:$PATH
CMD /start.sh

EXPOSE 8140

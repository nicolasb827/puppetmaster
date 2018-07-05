FROM centos:7
MAINTAINER nicolas.belan@gmail.com
LABEL network.b2.version="1.0.0"
LABEL vendor="B2 Network"
LABEL network.b2.release-date="2017-06-01"
LABEL network.b2.version.is-production="0"
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="e.g. https://github.com/microscaling/microscaling"

ARG VCS_REF

# set to 1 to autosign client cert (should be set in dev/testing)
ARG AUTOSIGN
# set to not empty string to restrict autosign to a single domain
ARG AUTOSIGN_DOMAIN

# precise env used
ARG ENVIRONMENT
ARG http_proxy

# VOLUMES
VOLUME /etc/puppetlabs/hieradata /etc/puppetlabs/code/environments/production /etc/puppetlabs/code/environments/dev /etc/puppetlabs/code/modules

RUN if [ "" != "$http_proxy" ]; then echo -e "proxy=http://$http_proxy\n" | tee -a /etc/yum.conf; fi
RUN groupadd puppet
RUN useradd -g puppet puppet
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
RUN yum -y install which hostname tar puppetserver rsync git
RUN mkdir /repo
RUN mkdir -p /etc/puppetlabs/code/environments
RUN mkdir -p /etc/puppetlabs/code/modules
RUN mkdir -p /etc/puppetlabs/hieradata

#WORKDIR /etc/puppetlabs/code
#RUN git clone https://nbelan@bitbucket.org/nbelan/puppetv4_env.git production
#RUN git clone https://nbelan@bitbucket.org/nbelan/puppetv4_env.git -b dev dev

COPY start.sh /start.sh
COPY puppetserver/auth.conf /etc/puppetlabs/puppetserver/conf.d/auth.conf
COPY puppetserver/master.conf /master.conf
COPY puppetserver/hiera.yaml /hiera.yaml
COPY puppetserver/sysconfig.puppetserver  /sysconfig.puppetserver
COPY puppetserver/production/ /repo/


# allow puppet path in PATH
ENV PATH /opt/puppetlabs/bin/:$PATH
ENV AUTOSIGN ${AUTOSIGN}
ENV AUTOSIGN_DOMAIN ${AUTOSIGN_DOMAIN}
ENV ENVIRONMENT ${ENVIRONMENT}



# ENTRYPOINT
CMD /start.sh $AUTOSIGN $ENVIRONMENT $AUTOSIGN_DOMAIN

EXPOSE 8140

FROM		scholzj/centos-builder-base:centos7-latest
LABEL           maintainer="Jakub Scholz <www@scholzj.com>"

ARG FTP_USERNAME
ARG FTP_PASSWORD
ARG FTP_HOSTNAME

USER root

# Install Qpid Proton and Qpid Python dependency
RUN curl -o /etc/yum.repos.d/qpid-proton-devel.repo http://repo.effectivemessaging.com/qpid-proton-devel.repo \
        && curl -o /etc/yum.repos.d/qpid-python-devel.repo http://repo.effectivemessaging.com/qpid-python-devel.repo \
        && yum -y --setopt=tsflag=nodocs --exclude=python2-qpid\* --disablerepo=extras install qpid-proton-c qpid-proton-c-devel python-qpid-proton python-qpid python-qpid-common && yum clean all

# Create the RPMs
RUN rpmdev-setuptree
WORKDIR /root/rpmbuild/SOURCES

RUN wget https://github.com/apache/qpid-cpp/archive/master.tar.gz
RUN tar -xf master.tar.gz
RUN mv qpid-cpp-master/ qpid-cpp-1.40.0/
RUN tar -z -cf qpid-cpp-1.40.0.tar.gz qpid-cpp-1.40.0/
RUN rm -rf master.tar.gz qpid-cpp-1.40.0/

ADD ./qpid-cpp.spec /root/rpmbuild/SPECS/qpid-cpp.spec

WORKDIR /root/rpmbuild/SPECS
RUN rpmbuild -ba qpid-cpp.spec

# Create and deploy the RPMs to the repository
RUN mkdir -p /root/repo/CentOS/7/x86_64
RUN mkdir -p /root/repo/CentOS/7/SRPMS
RUN mv /root/rpmbuild/RPMS/x86_64/*.rpm /root/repo/CentOS/7/x86_64/
RUN mv /root/rpmbuild/RPMS/noarch/*.rpm /root/repo/CentOS/7/x86_64/
RUN mv /root/rpmbuild/SRPMS/*.rpm /root/repo/CentOS/7/SRPMS/
WORKDIR /root/repo/CentOS/7/x86_64/
RUN createrepo .
WORKDIR /root/repo/CentOS/7/SRPMS
RUN createrepo .
RUN ncftpget -u $FTP_USERNAME -p $FTP_PASSWORD -R -DD $FTP_HOSTNAME /tmp/ /web/repo/qpid-cpp-devel/
RUN ncftpput -u $FTP_USERNAME -p $FTP_PASSWORD -R $FTP_HOSTNAME /web/repo/qpid-cpp-devel/ /root/repo/*

# Nothing to run
CMD    /bin/bash

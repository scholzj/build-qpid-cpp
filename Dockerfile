# DISPATCH
#
# VERSION               0.0.1

FROM		centos:centos7
MAINTAINER 	JAkub Scholz "www@scholzj.com"

ARG FTP_USERNAME
ARG FTP_PASSWORD
ARG FTP_HOSTNAME

# Install all dependencies
USER root

RUN curl -o /etc/yum.repos.d/qpid-proton-testing.repo http://repo.effectivemessaging.com/qpid-proton-testing.repo \
        && curl -o /etc/yum.repos.d/qpid-python-testing.repo http://repo.effectivemessaging.com/qpid-python-testing.repo \
        && yum -y --setopt=tsflag=nodocs install qpid-proton-c qpid-proton-c-devel python-qpid-proton python-qpid python-qpid-common && yum clean all

RUN yum -y install epel-release \
        && yum -y install wget tar rpm-build rpmdevtools createrepo ncftp cmake boost-devel libuuid-devel pkgconfig gcc-c++ make ruby help2man doxygen graphviz cyrus-sasl-devel nss-devel nspr-devel xqilla-devel xerces-c-devel ruby ruby-devel swig libdb-cxx-devel libaio-devel cyrus-sasl-plain cyrus-sasl-md5 perl-ExtUtils-MakeMaker.noarch libtool python-devel python-setuptools libdb4-cxx-devel libibverbs-devel librdmacm-devel

# Install Qpid Proton dependency
RUN wget http://repo.effectivemessaging.com/qpid-proton-stable.repo -P /etc/yum.repos.d
RUN yum -y install qpid-proton-c qpid-proton-c-devel python-qpid-proton

# Create the RPMs
RUN rpmdev-setuptree
WORKDIR /root/rpmbuild/SOURCES

RUN wget https://github.com/apache/qpid-cpp/archive/1.35.0-beta.tar.gz
RUN tar -xf 1.35.0-beta.tar.gz
RUN mv qpid-cpp-1.35.0-beta/ qpid-cpp-1.35.0/
RUN tar -z -cf qpid-cpp-1.35.0.tar.gz qpid-cpp-1.35.0/
RUN rm -rf 1.35.0-beta.tar.gz qpid-cpp-1.35.0-beta/

ADD ./0001-NO-JIRA-qpidd.service-file-for-use-on-Fedora.patch /root/rpmbuild/SOURCES/0001-NO-JIRA-qpidd.service-file-for-use-on-Fedora.patch
ADD ./0002-NO-JIRA-Allow-overriding-the-Perl-install-location.patch /root/rpmbuild/SOURCES/0002-NO-JIRA-Allow-overriding-the-Perl-install-location.patch
ADD ./0003-NO-JIRA-Allow-overriding-the-Ruby-install-location.patch /root/rpmbuild/SOURCES/0003-NO-JIRA-Allow-overriding-the-Ruby-install-location.patch
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
RUN ncftpget -u $FTP_USERNAME -p $FTP_PASSWORD -R -DD $FTP_HOSTNAME /tmp/ /web/repo/qpid-cpp-testing/
RUN ncftpput -u $FTP_USERNAME -p $FTP_PASSWORD -R $FTP_HOSTNAME /web/repo/qpid-cpp-testing/ /root/repo/*

# Nothing to run
CMD    /bin/bash

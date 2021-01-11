#!/bin/bash -x

set -eo pipefail

export MYSQL_VERSION=8.0.21

# $1=OPENSHIFT_CI=true means running in CI
if [[ "$1" == "true" ]]; then

	yum -y install --setopt=skip_missing_names_on_install=False \
		java-1.8.0-openjdk \
		java-1.8.0-openjdk-devel

	pushd /tmp
	curl -o maven.tgz https://downloads.apache.org/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
	tar zxvf maven.tgz
	export M2_HOME=/tmp/apache-maven-3.3.9
	export PATH=${PATH}:${M2_HOME}/bin
	popd

	mvn dependency:get -Dartifact=mysql:mysql-connector-java:${MYSQL_VERSION} -Ddest=/build/mysql-connector-java.jar
  	mvn -B -e -T 1C -DskipTests=true -DfailIfNoTests=false -Dtest=false clean package -Pdist
else
    # Otherwise this is a production brew build by ART
	export RH_HIVE_PATCH_VERSION=00002
	export HIVE_VERSION=2.3.3

	export HIVE_RELEASE_URL=http://download.eng.bos.redhat.com/brewroot/packages/org.apache.hive-hive/${HIVE_VERSION}.redhat_${RH_HIVE_PATCH_VERSION}/1/maven/org/apache/hive/hive-packaging/${HIVE_VERSION}.redhat-${RH_HIVE_PATCH_VERSION}/hive-packaging-${HIVE_VERSION}.redhat-${RH_HIVE_PATCH_VERSION}-bin.tar.gz
	export HIVE_OUT=/build/packaging/target/apache-hive-$HIVE_VERSION-bin/apache-hive-$HIVE_VERSION-bin

	curl -fSLs \
	  $HIVE_RELEASE_URL \
	  -o /tmp/hive-bin.tar.gz

	mkdir -p $(dirname $HIVE_OUT) && \
	  tar -xvf /tmp/hive-bin.tar.gz -C /tmp \
	  && mv /tmp/apache-hive-${HIVE_VERSION}.redhat-${RH_HIVE_PATCH_VERSION}-bin/ \
	  $HIVE_OUT

	# Note(tflannag): In previous metering releases, we got the mysql-connector-java jar
	# for free. Now, images use RHEL8 as the base image and in order to maintain upgrades
	# to 4.6+ releases, curl that build from PNC (.tar.gz is also available) and move to
	# the correct path in the destination container in the Dockerfile workflow.
	export RH_MYSQL_CONNECTOR_PATCH_VERSION=00001
	curl -fSLs \
		http://download.eng.bos.redhat.com/brewroot/packages/mysql-mysql-connector-java/${MYSQL_VERSION}.redhat_${RH_MYSQL_CONNECTOR_PATCH_VERSION}/1/maven/mysql/mysql-connector-java/${MYSQL_VERSION}.redhat-${RH_MYSQL_CONNECTOR_PATCH_VERSION}/mysql-connector-java-${MYSQL_VERSION}.redhat-${RH_MYSQL_CONNECTOR_PATCH_VERSION}.jar \
		-o /build/mysql-connector-java.jar
fi

FROM ubuntu:20.04
LABEL maintainer="Denis Rystsov <denis@redpanda.com>"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y
RUN apt install -f -y
RUN apt install -y wget ssh sudo --fix-missing
RUN apt install -y openjdk-11-jdk maven
RUN cd /root && wget https://downloads.apache.org/zookeeper/zookeeper-3.8.1/apache-zookeeper-3.8.1-bin.tar.gz && tar xzf apache-zookeeper-3.8.1-bin.tar.gz && rm apache-zookeeper-3.8.1-bin.tar.gz
RUN cd /root && wget https://downloads.apache.org/kafka/3.4.0/kafka_2.12-3.4.0.tgz && tar xzf kafka_2.12-3.4.0.tgz && rm kafka_2.12-3.4.0.tgz
RUN apt install -y python3-pip --fix-missing
RUN pip3 install 'confluent_kafka==1.9.2'
COPY entrypoint.sh /entrypoint.sh
CMD /entrypoint.sh
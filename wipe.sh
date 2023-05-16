#!/bin/bash

cat kafka1/pid kafka2/pid kafka3/pid | xargs kill -9
cat zookeeper/zookeeper_server.pid | xargs kill -9
rm -rf zookeeper/zookeeper_server.pid
rm -rf zookeeper/version-2
rm -rf kafka1/data
rm -rf kafka2/data
rm -rf kafka3/data
rm -rf kafka1/kafka.log
rm -rf kafka2/kafka.log
rm -rf kafka3/kafka.log
rm -rf kafka1/pid
rm -rf kafka2/pid
rm -rf kafka3/pid

mkdir /fsync/kafka1/data
mkdir /fsync/kafka2/data
mkdir /fsync/kafka3/data

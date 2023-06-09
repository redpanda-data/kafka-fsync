## Local data loss on a single node causes global data loss in Kafka cluster

Clone this repo

    git clone https://github.com/redpanda-data/kafka-fsync.git
    cd kafka-fsync

Build a container with a locally-deployed Kafka cluster (three Kafka processes and one Apache ZooKeeper™ process)

    docker build -t kafka-fsync .

Start the container and log into it

    docker run -d --name kafka_fsync -v $(pwd):/fsync kafka-fsync
    docker exec -it kafka_fsync /bin/bash

Create data directories

    cd /fsync
    ./create.dirs.sh

Start the ZooKeeper process

    /root/apache-zookeeper-3.8.1-bin/bin/zkServer.sh --config . start

Start three Kafka processes

    nohup /root/kafka_2.12-3.4.0/bin/kafka-server-start.sh kafka1/server.properties >> /fsync/kafka1/kafka.log 2>&1 & echo $! > /fsync/kafka1/pid &
    nohup /root/kafka_2.12-3.4.0/bin/kafka-server-start.sh kafka2/server.properties >> /fsync/kafka2/kafka.log 2>&1 & echo $! > /fsync/kafka2/pid &
    nohup /root/kafka_2.12-3.4.0/bin/kafka-server-start.sh kafka3/server.properties >> /fsync/kafka3/kafka.log 2>&1 & echo $! > /fsync/kafka3/pid &

Create topic1 with RF=3:

    /root/kafka_2.12-3.4.0/bin/kafka-topics.sh --create --topic topic1 --partitions 1 --replication-factor 3 --bootstrap-server 127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094

Kill Kafka process 1. Because the OS or node wasn't crashed, kafka1 hasn't experienced local data loss

    cat kafka1/pid | xargs kill -9

Write ten records with acks=all

    python3 write10.py

Output

    wrote key0=value0 at offset=0
    wrote key1=value1 at offset=1
    ...
    wrote key8=value8 at offset=8
    wrote key9=value9 at offset=9

Let's figure out which node is the leader

    /root/kafka_2.12-3.4.0/bin/kafka-topics.sh --describe --topic topic1 --bootstrap-server 127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094

On my machine it was kafka3. Let's kill ZooKeeper (isolate ZooKeeper from the cluster) to "freeze" leadership on the third node

    cat zookeeper/zookeeper_server.pid | xargs kill -9

Kill the rest Kafka processes to freeze time. Since the OS is intact, there’s no local data loss at this point

    cat kafka2/pid kafka3/pid | xargs kill -9

Now we simulate local data loss by removing the last ten bytes from the last leader (kafka3, in my case)

    truncate -s -10 kafka3/data/topic1-0/00000000000000000000.log

Restart ZooKeeper

    /root/apache-zookeeper-3.8.1-bin/bin/zkServer.sh --config . start

Let's give it a minute to remove ephemeral info. Then start the former leader (kafka3, in my case)

    nohup /root/kafka_2.12-3.4.0/bin/kafka-server-start.sh kafka3/server.properties >> /fsync/kafka3/kafka.log 2>&1 & echo $! > /fsync/kafka3/pid &

Wait until it becomes a leader

    /root/kafka_2.12-3.4.0/bin/kafka-topics.sh --describe --topic topic1 --bootstrap-server 127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094

Then start "empty" kafka1 process

    nohup /root/kafka_2.12-3.4.0/bin/kafka-server-start.sh kafka1/server.properties >> /fsync/kafka1/kafka.log 2>&1 & echo $! > /fsync/kafka1/pid &

Again, let's wait until two nodes ISR form

    /root/kafka_2.12-3.4.0/bin/kafka-topics.sh --describe --topic topic1 --bootstrap-server 127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094

Then, let's write another ten records to Kafka

    python3 write10.py

Ideally, we should see

    wrote key0=value0 at offset=10
    wrote key1=value1 at offset=11
    ...
    wrote key8=value8 at offset=18
    wrote key9=value9 at offset=19

But what we actually see is

    wrote key0=value0 at offset=9
    wrote key1=value1 at offset=10
    ...
    wrote key8=value8 at offset=17
    wrote key9=value9 at offset=18

So, by causing local data loss on a single node (it may happen without the fsync) we caused global data loss and Kafka lost record key9=value9 at offset=9.

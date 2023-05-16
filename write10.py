from confluent_kafka import (Producer, KafkaException)

def on_delivery(err, msg):
    if err is not None:
        raise KafkaException(err)
    print(f"wrote {msg.key().decode()}={msg.value().decode()} at offset={msg.offset()}")

producer = Producer({
    "bootstrap.servers": "127.0.0.1:9092,127.0.0.1:9093,127.0.0.1:9094",
    "acks": "all"
})

for i in range(0,10):
    producer.produce("topic1",
                        key=f"key{i}".encode('utf-8'),
                        value=f"value{i}".encode('utf-8'),
                        callback=on_delivery)
    producer.flush()
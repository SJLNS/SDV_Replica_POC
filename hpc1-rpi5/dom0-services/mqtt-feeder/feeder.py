"""
MQTT -> KUKSA VSS feeder for HPC-1 / ZCU-1.

Subscribes to ZCU-1's MQTT topics (over TLS 1.3, mutual auth) and writes
matching values into the local KUKSA Databroker's VSS tree. This is the
standard KUKSA "provider" integration pattern referenced in the architecture
doc — extend VSS_TOPIC_MAP as you add real signals, and add the reverse
direction (VSS actuation target -> MQTT publish) once this direction is
proven working end to end.

Dependencies: paho-mqtt, kuksa-client
    pip install --break-system-packages paho-mqtt kuksa-client
"""

import logging

import paho.mqtt.client as mqtt
from kuksa_client.grpc import Datapoint, VSSClient

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("mqtt-feeder")

BROKER_HOST = "mosquitto"
BROKER_PORT = 8883
DATABROKER_HOST = "localhost"
DATABROKER_PORT = 55555

CA_CERT = "/certs/ca.crt"
CLIENT_CERT = "/certs/feeder.crt"
CLIENT_KEY = "/certs/feeder.key"

VSS_TOPIC_MAP = {
    "zcu1/sensor/temperature": "Vehicle.SDVReplica.ZCU1.Temperature",
}


def on_connect(client, userdata, flags, rc):
    if rc != 0:
        log.error("MQTT connect failed, rc=%s", rc)
        return
    log.info("connected to broker, subscribing to zcu1/#")
    client.subscribe("zcu1/#")


def on_message(client, userdata, msg):
    vss_path = VSS_TOPIC_MAP.get(msg.topic)
    if not vss_path:
        log.debug("no VSS mapping for topic %s, skipping", msg.topic)
        return
    try:
        value = float(msg.payload.decode())
    except ValueError:
        log.warning("could not parse payload on %s: %r", msg.topic, msg.payload)
        return

    with VSSClient(DATABROKER_HOST, DATABROKER_PORT) as vss:
        vss.set_current_values({vss_path: Datapoint(value)})
    log.info("%s -> %s = %s", msg.topic, vss_path, value)


def main():
    client = mqtt.Client()
    client.tls_set(ca_certs=CA_CERT, certfile=CLIENT_CERT, keyfile=CLIENT_KEY)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(BROKER_HOST, BROKER_PORT)
    client.loop_forever()


if __name__ == "__main__":
    main()

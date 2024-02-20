import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final client = MqttServerClient.withPort("broker.hivemq.com", "", 1883);
  final String topic = "demomqtt";
  final TextEditingController messageController = TextEditingController();
  List<String> messageList = [];
  String connectionStatus = 'No status yet';

  @override
  void initState() {
    super.initState();

    mqttConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade300,
        centerTitle: true,
        title: const Text(
          'MQTT Protocol - HiveMQ',
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(connectionStatus,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(
                height: 20,
              ),
              messageList.isEmpty
                  ? const Center(
                      child: Text('Start your conversation here ...',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messageList.length,
                      itemBuilder: (context, index) {
                        return Text(
                          messageList[index],
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        );
                      }),
              const SizedBox(
                height: 100,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.black, width: 1)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          )),
                      onChanged: (value) {
                        setState(() {
                          messageController.text = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        sendMessage();
                        messageController.clear();
                      },
                      child: const Text(
                        'Send',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void mqttConnection() async {
    client.setProtocolV31();
    client.logging(on: true);
    client.keepAlivePeriod = 120;
    client.autoReconnect = true;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribe;

    final MqttConnectMessage connectMessage = MqttConnectMessage()
        .withClientIdentifier(DateTime.now().toString())
        .startClean();
    client.connectionMessage = connectMessage;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to AWS Successfully................");
    } else {
      await client.connect();
    }

    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> msg) {
      final MqttPublishMessage recMessage =
          msg[0].payload as MqttPublishMessage;

      final pt =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      // final json = jsonDecode(pt);
      // messageList.add(json['msg']);
      messageList.add(pt);
      setState(() {});
    });
  }

  void onConnected() {
    setState(() {
      connectionStatus = "Connected";
    });
  }

  void onDisconnected() {
    setState(() {
      connectionStatus = "Disconnected";
    });
  }

  void onSubscribe(String topic) {
    setState(() {
      connectionStatus = "Subscribed to : $topic";
    });
  }

  void sendMessage() {
    final String pubTopic = topic;
    final builder = MqttClientPayloadBuilder();
    builder.addString(messageController.text);
    client.subscribe(pubTopic, MqttQos.atLeastOnce);
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }
}

import 'package:fl_tidal101/page/index/index_controller.dart';
import 'package:fl_tidal101/widget/spectrogram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class IndexPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _IndexState();
}

class _IndexState extends State<IndexPage> with SingleTickerProviderStateMixin {
  IndexController controller = Get.find();
  Ticker? _ticker;

  void _incrementCounter() {
    debugPrint("_numFreq: ${controller.spectrogramHorizontalCount}");
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _ticker = Ticker(controller.updateFps)..start();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Stack(
        children: [
          Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Obx(() => Spectrogram(
                  data: controller.buffer.value,
                  horizontalCount: controller.spectrogramHorizontalCount,
                  intensityColorMap: controller.intensityColorMaps[
                      controller.intensityColorMapIndex.value],
                  debug: false))),
          Container(
            color: const Color(0xAAFFFFFF),
            child: Obx(() => Text("${controller.currentFps}fps")),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

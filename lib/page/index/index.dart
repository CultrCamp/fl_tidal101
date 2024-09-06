import 'package:file_picker/file_picker.dart';
import 'package:fl_tidal101/common/rf_controller.dart';
import 'package:fl_tidal101/page/index/index_controller.dart';
import 'package:fl_tidal101/utils/benchmark_util.dart';
import 'package:fl_tidal101/widget/frequecy_axis.dart';
import 'package:fl_tidal101/widget/spectrogram_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<StatefulWidget> createState() => _IndexState();
}

class _IndexState extends State<IndexPage> with SingleTickerProviderStateMixin {
  IndexController controller = Get.find();
  RfService rfService = Get.find();
  Ticker? _ticker;

  void _incrementCounter() async {
    if (kDebugMode) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        debugPrint("load file: ${result.files.single.path!}");
        controller.doSTFT(result.files.single.path!);
      }
    } else {
      debugPrint("load hard coded");
      controller.doSTFT("/root/sample1.wav");
    }
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
      body: Container(
        color: Colors.black,
        child: LayoutBuilder(builder: (ctx, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                color: const Color(0xAAFFFFFF),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Obx(() => Text(
                          "${controller.currentFps.value.toString().padLeft(3, '0')}fps")),
                    ),
                    SizedBox.fromSize(
                        size: Size(50, constraints.maxHeight * 0.05)),
                    Obx(() => Text(
                        "total: ${controller.totalDuration.toStringAsFixed(2)} "
                        "current: ${controller.currentDuration.toStringAsFixed(2)} "
                        "samplates: ${controller.samplesPerSecond} "
                        "bit: ${controller.bitPerSample} "
                        "buckets: ${IndexController.buckets} "
                        "resolution: ${controller.samplesPerSecond / IndexController.buckets}")),
                    const Spacer(),
                    TextButton(
                        onPressed: _incrementCounter,
                        child: const Text("Start"))
                  ],
                ),
              ),
              SizedBox.fromSize(
                size: Size(constraints.maxWidth, constraints.maxHeight * 0.5),
                child: Container(
                  color: Colors.amber,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [Text("VFO: ${rfService.vfoKh}")],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox.fromSize(
                  size: Size.fromHeight(constraints.maxHeight * 0.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Obx(() => SpectrogramImage(
                              data: controller.buffer.value,
                              intensityColorMap: controller.intensityColorMaps[
                                  controller.intensityColorMapIndex.value],
                              debug: false,
                              durationCallback: (duration) {
                                var now = DateTime.now();
                                if (now
                                        .difference(controller.measureStart)
                                        .inSeconds >=
                                    5) {
                                  debugPrint(
                                      "render duration average: ${getDurationAverageInMillis(controller.durations)}ms list: [${printDurationsInMillis(controller.durations)}]");
                                  controller.measureStart = now;
                                  controller.durations.clear();
                                }
                                controller.durations.add(duration);
                              },
                            )),
                      ),
                      Container(
                          color: Colors.black,
                          child: Obx(() => Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  SizedBox.fromSize(
                                    size: const Size(10, 10),
                                  ),
                                  FrequencyAxis(
                                      numLabels: 10,
                                      maxFrequency:
                                          controller.samplesPerSecond.value ~/
                                              2) //  Nyquist
                                ],
                              ))),
                    ],
                  )),
            ],
          );
        }),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

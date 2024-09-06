import 'package:fl_tidal101/common/rf_controller.dart';
import 'package:get/get.dart';

class CommonBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put(RfService());
  }
}

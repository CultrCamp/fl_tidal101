import 'package:fl_tidal101/page/index/index.dart';
import 'package:fl_tidal101/page/index/index_controller.dart';
import 'package:get/get.dart';

class Routes {
  static const IndexPage = "/";
}

final pages = [
  GetPage(
      name: Routes.IndexPage, page: () => IndexPage(), binding: IndexBinding())
];

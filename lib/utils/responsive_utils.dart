import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ResponsiveNum on num {
  /// Scales width
  double get w => ScreenUtil().setWidth(this);

  /// Scales height
  double get h => ScreenUtil().setHeight(this);

  /// Scales font size
  double get sp => ScreenUtil().setSp(this);

  /// Scales radius
  double get r => ScreenUtil().radius(this);
}

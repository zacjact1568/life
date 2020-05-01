enum DateTimeStringType {
  // 2020-04-25T21:57:21.081343+08:00
  NETWORK,
  // 2020-04-25 13:57:21.081343
  LOCAL,
  // 2020-04-25
  DATE,
  // 2020-04-25 21:57
  DATE_TIME,
}

/// 根据 [type] 使用 [dateTime] 构建 DateTime 对象
/// 生成的 DateTime 对象为 UTC 时间
DateTime parseDateTimeString(String dateTime, DateTimeStringType type) {
  var str;
  switch (type) {
    case DateTimeStringType.NETWORK:
      // 后端返回的是 ISO-8601 格式的时间字符串
      // e.g. 2020-04-25T21:57:21.081343+08:00
      // 指明了时区，会在 DateTime 内部转换为 UTC 时区（isUtc == true）
      str = dateTime;
      break;
    case DateTimeStringType.LOCAL:
      // 本地数据库返回 UTC 时间的字符串（为了跟后端数据库保持一致）
      // e.g. 2020-04-25 13:57:21.081343
      // 没有表明时区，会被当做本地时区处理（isUtc == false）
      // 因此需手动加上 UTC 时区指示符 Z（isUtc == true）
      str = dateTime + 'Z';
      break;
    default:
      throw ArgumentError.value(type, 'type');
  }
  // 都可以用 DateTime.parse 解析
  // 生成的 DateTime 的 isUtc 一定为 true
  return DateTime.parse(str);
}

/// 根据 [type] 获取 [dateTime] 中的时间字符串
/// [dateTime] 必须为 UTC 时间
String toDateTimeString(DateTime dateTime, DateTimeStringType type) {
  assert(dateTime.isUtc);
  switch (type) {
    case DateTimeStringType.NETWORK:
      // 供上传到后端
      // 直接使用 ISO-8601 格式（UTC 时区）即可
      // TODO 是否可以在创建时指定时间？
      // TODO 是否可以上传 UTC 时间？
      return dateTime.toIso8601String();
    case DateTimeStringType.LOCAL:
      // 供存储到本地（使用 UTC）
      // toString 返回的是 2020-04-25 13:57:21.081343Z 格式
      var replace;
      if (dateTime.microsecond == 0) {
        // 如果微秒为 0，不会添加 0
        // 所以用 000 替换 Z
        replace = '000';
      } else {
        // 如果微秒不为 0
        // 直接去掉 Z
        replace = '';
      }
      return dateTime.toString().replaceAll(RegExp(r'Z'), replace);
    case DateTimeStringType.DATE:
      // 供显示到界面上（仅年月日，使用本地时间）
      final local = dateTime.toLocal();
      final y = local.year;
      final m = _twoDigits(local.month);
      final d = _twoDigits(local.day);
      return '$y-$m-$d';
    case DateTimeStringType.DATE_TIME:
      // 供显示到界面上（年月日时分，使用本地时间）
      final local = dateTime.toLocal();
      final y = local.year;
      final m = _twoDigits(local.month);
      final d = _twoDigits(local.day);
      final h = _twoDigits(local.hour);
      final min = _twoDigits(local.minute);
      return '$y-$m-$d $h:$min';
    default:
      throw ArgumentError.value(type, 'type');
  }
}

/// 检查是否过期
bool checkExpired(DateTime start, int thresholdInHour) {
  final duration = DateTime.now().toUtc().difference(start);
  return duration.inHours >= thresholdInHour;
}

String _twoDigits(int digit) {
  assert(digit < 100 && digit >= 0);
  if (digit < 10) {
    // 一位数字
    return '0$digit';
  }
  // 两位数字
  return digit.toString();
}

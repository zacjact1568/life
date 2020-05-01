import 'package:shared_preferences/shared_preferences.dart';

import 'package:life/util/time.dart';

const _PREF_BLOG_POST_LAST_REFRESHING_TIME = 'blog_post_last_refreshing_time';
const _PREF_BLOG_POST_TOTAL_COUNT = 'blog_post_total_count';

Future<DateTime> getPostLastRefreshingTime() async {
  // SharedPreferences 内部实现了缓存
  // 所以可以直接取，不用自己再去缓存一次了
  final pref = await SharedPreferences.getInstance();
  final dateTimeStr = pref.getString(_PREF_BLOG_POST_LAST_REFRESHING_TIME);
  if (dateTimeStr == null) {
    // 没有保存该值
    return null;
  }
  return parseDateTimeString(dateTimeStr, DateTimeStringType.LOCAL);
}

Future<void> setNowAsPostLastRefreshingTime() async {
  final pref = await SharedPreferences.getInstance();
  final dateTime = DateTime.now().toUtc();
  final dateTimeStr = toDateTimeString(dateTime, DateTimeStringType.LOCAL);
  pref.setString(_PREF_BLOG_POST_LAST_REFRESHING_TIME, dateTimeStr);
}

Future<int> getTotalPostCount() async {
  final pref = await SharedPreferences.getInstance();
  // 没有保存该值的话，会返回 null
  return pref.getInt(_PREF_BLOG_POST_TOTAL_COUNT);
}

Future<void> setTotalPostCount(int count) async {
  final pref = await SharedPreferences.getInstance();
  pref.setInt(_PREF_BLOG_POST_TOTAL_COUNT, count);
}

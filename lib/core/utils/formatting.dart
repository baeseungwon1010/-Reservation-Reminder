import 'package:intl/intl.dart';

/// 날짜/시간 표시 포맷 모음.
class Fmt {
  Fmt._();

  static final _ymd = DateFormat('yyyy.MM.dd');
  static final _md = DateFormat('MM.dd');
  static final _mdE = DateFormat('MM.dd (E)', 'ko_KR');
  static final _ymdE = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
  static final _hm = DateFormat('HH:mm');
  static final _ym = DateFormat('yyyy년 M월');

  static String ymd(DateTime d) => _ymd.format(d);
  static String md(DateTime d) => _md.format(d);
  static String mdWeekday(DateTime d) => _mdE.format(d);
  static String ymdWeekday(DateTime d) => _ymdE.format(d);
  static String hm(DateTime d) => _hm.format(d);
  static String ym(DateTime d) => _ym.format(d);
  static String dateTime(DateTime d) => '${_ymd.format(d)} ${_hm.format(d)}';
}

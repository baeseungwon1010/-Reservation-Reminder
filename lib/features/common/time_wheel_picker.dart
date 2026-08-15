import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 위아래로 드래그(스크롤)해서 시간을 고르는 휠 방식 시간 선택기(#2).
/// 기존 원형 시계 대신 사용한다. 24시간제.
Future<TimeOfDay?> pickTimeWheel(
  BuildContext context, {
  required TimeOfDay initial,
  String title = '시간 선택',
}) {
  var selected = initial;
  final now = DateTime.now();
  var temp = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(ctx).brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 1,
                  initialDateTime: temp,
                  onDateTimeChanged: (dt) {
                    temp = dt;
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

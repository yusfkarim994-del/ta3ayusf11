import 'package:record/record.dart';

void main() async {
  final record = Record();
  await record.hasPermission();
  await record.start(path: 'test.m4a', encoder: AudioEncoder.aacLc);
  await record.stop();
  record.dispose();
}

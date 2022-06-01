// import 'package:flutter_test/flutter_test.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// import 'package:stater/src.dart';
// import 'package:stater/src_method_channel.dart';
// import 'package:stater/src_platform_interface.dart';

// class MockStaterPlatform
//     with MockPlatformInterfaceMixin
//     implements StaterPlatform {
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final StaterPlatform initialPlatform = StaterPlatform.instance;

//   test('$MethodChannelStater is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelStater>());
//   });

//   test('getPlatformVersion', () async {
//     Stater staterPlugin = Stater();
//     MockStaterPlatform fakePlatform = MockStaterPlatform();
//     StaterPlatform.instance = fakePlatform;

//     expect(await staterPlugin.getPlatformVersion(), '42');
//   });
// }

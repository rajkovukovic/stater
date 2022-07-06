import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'make sure derived adapters have ids set by '
      'their constructor', () async {
    final inMemoryAdapter =
        InMemoryAdapter(generateSampleData(), id: 'inMemoryAdapterId');

    expect(inMemoryAdapter.id, 'inMemoryAdapterId');
  });

  test(
      'make sure proxy adapters have ids set by '
      'their constructor', () async {
    final inMemoryAdapter =
        InMemoryAdapter(generateSampleData(), id: 'inMemoryAdapterId');

    final delayedAdapter = DelayedAdapter(inMemoryAdapter,
        readDelay: const Duration(milliseconds: 50),
        writeDelay: const Duration(milliseconds: 100),
        id: 'delayedAdapterId');

    expect(inMemoryAdapter.id, 'inMemoryAdapterId');
    expect(delayedAdapter.id, 'delayedAdapterId');
  });

  test(
      'make sure double proxy adapters have ids set by their '
      'constructor', () async {
    final inMemoryAdapter =
        InMemoryAdapter(generateSampleData(), id: 'inMemoryAdapterId');

    final delayedAdapter = DelayedAdapter(inMemoryAdapter,
        readDelay: const Duration(milliseconds: 50),
        writeDelay: const Duration(milliseconds: 100),
        id: 'delayedAdapterId');

    final lockingAdapter =
        LockingAdapter(delayedAdapter, id: 'lockingAdapterId');

    expect(inMemoryAdapter.id, 'inMemoryAdapterId');
    expect(delayedAdapter.id, 'delayedAdapterId');
    expect(lockingAdapter.id, 'lockingAdapterId');
  });
}

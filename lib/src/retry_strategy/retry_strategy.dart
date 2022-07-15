/// Defines a retry strategy for a transaction.
/// Must implement method [getNextRetry] which
/// should return a Future that resolves after some Duration.
/// When the future resolves, next retry will start.
/// If Future fails there will be no more retries and error of the last retry
/// will be propagated to the transaction processor.
abstract class RetryStrategy {
  Future getNextRetry({
    required int retryIndex,
    // required Transaction transaction,
  });
}

/// If intervals are equal to [0.5, 2, 8], it will retry a transaction
/// 0.5s after first failure, 2s after seconds failure, 8s after third
/// and every next failure.
///
/// It will return Future.error if number of retries exceeds maxRetries.
/// To retry forever maxRetries must be null.
class RetryByIntervals extends RetryStrategy {
  late final List<int> intervals;
  final int? maxRetries;

  RetryByIntervals({
    required List<num> intervalsInSeconds,
    this.maxRetries,
  })  : assert(intervalsInSeconds.isNotEmpty, 'intervals must have values'),
        assert(maxRetries == null || maxRetries >= 0,
            'maxRetries must be null or non negative integer') {
    intervals = intervalsInSeconds
        .map((value) => (value.toDouble() * 1000).round())
        .toList();
  }

  @override
  Future getNextRetry({
    required int retryIndex,
    // required Transaction transaction,
  }) {
    if (maxRetries != null && retryIndex >= maxRetries!) {
      return Future.error('Exceeded max number of retries of $maxRetries');
    } else {
      final durationMilliseconds = intervals.length >= retryIndex
          ? intervals.last
          : intervals[retryIndex];

      return Future.delayed(Duration(milliseconds: durationMilliseconds));
    }
  }
}

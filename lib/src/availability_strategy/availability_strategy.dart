/// Defines an availability strategy for a Storage.<br>
/// When [isAvailable] is true Storage will process transactions.<br>
/// When [isAvailable] is false Storage will pause processing of transactions.<br>
/// [asStream] getter should return a stream that emits a new value
/// representing new availability state.
abstract class AvailabilityStrategy {
  bool get isAvailable;
  Stream<bool> get asStream;
}

import 'package:stater/stater.dart';

/// This is an empty mixin that should be used by all read operations.
///
/// Why?
///
/// We want to remove all read operations fro the transaction queue
/// when app closes, because read operation handlers will be lost
/// on app restart as well. It makes sense for the write operations only to be
/// preserved across app use sessions, because we do not want to lose write
/// operations only because user had to close the app or the app crashed, which
/// does not apply to the read operations.
///
/// We want to use this mixin to distinguish read from write operations so
/// only write operations can be persisted across app use sessions.
mixin ReadOperation on Operation {}

// ignore: camel_case_types
class CallCounter {
  final Function _fn;

  int counter = 0;

  CallCounter(this._fn);

  once() {
    counter++;
    _fn();
  }
}

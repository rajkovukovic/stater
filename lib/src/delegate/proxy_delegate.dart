import 'package:stater/stater.dart';

mixin ProxyDelegate on StorageDelegate {
  Future Function(String serviceName, dynamic params)? serviceRequestProxy;

  @override
  Future serviceRequest(String serviceName, params) {
    if (serviceRequestProxy != null) {
      return serviceRequestProxy!(serviceName, params);
    } else {
      return super.serviceRequest(serviceName, params);
    }
  }
}

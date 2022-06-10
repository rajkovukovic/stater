import 'package:dio/dio.dart';
import 'package:stater/custom/rest_delegate.dart';
import 'package:stater/src/storage.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/transaction/operation/operation.dart';
import 'package:stater/src/transaction/transaction.dart';

export 'package:stater/custom/rest_delegate.dart' show RestDelegate;

class RestStorage extends Storage {
  RestStorage(RestDelegate delegate) : super(delegate);

  @override
  RestDelegate get delegate => super.delegate as RestDelegate;

  Future _createTodoViaServiceProcessor(Map<String, dynamic> params) {
    return Dio()
        .post('${delegate.endpoint}/createTodoRequest', data: params)
        .then(
          (response) => Transaction(
            operations: [
              CreateOperation(
                data: response.data,
                documentId: response.data['id'],
                collectionName: 'todos',
              )
            ],
          ),
        );
  }

  Future _changeTodoOwner(Map<String, dynamic> params) {
    return Dio()
        .post('${delegate.endpoint}/changeTodoOwner', data: params)
        .then(
      (response) {
        return (StorageDelegate delegate) async {
          final todoSnapshot = await delegate.getDocument(
            collectionName: 'todos',
            documentId: params['todoId'],
          );

          await todoSnapshot.reference.set(<String, dynamic>{
            ...(todoSnapshot.data() as Map<String, dynamic>),
            'userId': params['userId']
          });
        };
      },
    );
  }

  @override
  Future request(String requestName, dynamic params) {
    switch (requestName) {
      case 'createTodoAddAssignToUser':
        return _createTodoViaServiceProcessor(params);
      case 'changeTodoOwner':
        return _changeTodoOwner(params);
      default:
        throw 'Not implemented request with name "$requestName"';
    }
  }
}

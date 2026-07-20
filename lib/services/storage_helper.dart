import 'storage_helper_stub.dart'
    if (dart.library.html) 'storage_helper_web.dart' as impl;

String? readFromLocalStorage(String key) => impl.StorageHelper.read(key);
void writeToLocalStorage(String key, String value) => impl.StorageHelper.write(key, value);

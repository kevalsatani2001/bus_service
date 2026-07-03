export 'printer_stub.dart'
    if (dart.library.js_util) 'printer_web.dart'
    if (dart.library.js) 'printer_web.dart'
    if (dart.library.html) 'printer_web.dart';

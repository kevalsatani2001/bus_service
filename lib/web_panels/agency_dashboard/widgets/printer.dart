import 'ticket_print_data.dart';
import 'printer_impl_stub.dart'
    if (dart.library.html) 'printer_web.dart'
    if (dart.library.io) 'printer_mobile.dart' as impl;

export 'ticket_print_data.dart';

Future<void> printTicket([TicketPrintData? data]) => impl.printTicketImpl(data);

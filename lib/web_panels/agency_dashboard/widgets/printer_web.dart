import 'package:universal_html/html.dart' as html;
import 'package:bus_service/web_panels/agency_dashboard/widgets/ticket_print_data.dart';

Future<void> printTicketImpl(TicketPrintData? data) async {
  if (data == null) {
    html.window.print();
    return;
  }

  final printDiv = html.DivElement()
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..innerHtml = '''
<div style="font-family:Arial,sans-serif;width:280px;padding:16px;">
  <div style="text-align:center;border-bottom:2px dashed #333;padding-bottom:8px;margin-bottom:12px;">
    <h2 style="margin:0;font-size:16px;">Bus Ticket</h2>
    <div>${data.ticketId}</div>
  </div>
  <div><b>Passenger:</b> ${data.passengerName}</div>
  <div><b>Phone:</b> ${data.passengerPhone}</div>
  <div><b>Seat:</b> ${data.seatNumber}</div>
  <div><b>Trip:</b> ${data.tripId}</div>
  <div><b>Boarding:</b> ${data.boardingPoint}</div>
  <div><b>Drop:</b> ${data.dropPoint}</div>
  <div style="text-align:center;margin:12px 0;">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=${Uri.encodeComponent(data.qrData)}" width="140"/>
  </div>
  <div style="text-align:center;font-size:10px;color:#888;border-top:2px dashed #333;padding-top:8px;">${data.trackingUrl}</div>
</div>
''';

  html.document.body?.append(printDiv);
  html.window.print();
  printDiv.remove();
}

/// Ticket data passed to the print layer.
class TicketPrintData {
  final String ticketId;
  final String passengerName;
  final String passengerPhone;
  final String seatNumber;
  final String tripId;
  final String boardingPoint;
  final String dropPoint;
  final String trackingUrl;
  final String qrData;

  const TicketPrintData({
    required this.ticketId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seatNumber,
    required this.tripId,
    required this.boardingPoint,
    required this.dropPoint,
    required this.trackingUrl,
    required this.qrData,
  });
}

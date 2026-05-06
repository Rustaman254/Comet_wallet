import 'package:equatable/equatable.dart';
import '../../models/ticket.dart';

enum TicketingStatus { initial, loading, success, failure }

class TicketingState extends Equatable {
  final TicketingStatus status;
  final List<Ticket> tickets;
  final Ticket? currentTicket;
  final String? errorMessage;
  final String? successMessage;

  const TicketingState({
    this.status = TicketingStatus.initial,
    this.tickets = const [],
    this.currentTicket,
    this.errorMessage,
    this.successMessage,
  });

  TicketingState copyWith({
    TicketingStatus? status,
    List<Ticket>? tickets,
    Ticket? currentTicket,
    String? errorMessage,
    String? successMessage,
  }) {
    return TicketingState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      currentTicket: currentTicket ?? this.currentTicket,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, tickets, currentTicket, errorMessage, successMessage];
}

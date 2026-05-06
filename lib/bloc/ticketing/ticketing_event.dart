import 'package:equatable/equatable.dart';

abstract class TicketingEvent extends Equatable {
  const TicketingEvent();

  @override
  List<Object?> get props => [];
}

class CreateTicketRequested extends TicketingEvent {
  final String? issueCategory;
  final String? issueDescription;

  const CreateTicketRequested({
    this.issueCategory,
    this.issueDescription,
  });

  @override
  List<Object?> get props => [issueCategory, issueDescription];
}

class CreateGuestTicketRequested extends TicketingEvent {
  final String userEmail;
  final String issueDescription;
  final String? issueCategory;

  const CreateGuestTicketRequested({
    required this.userEmail,
    required this.issueDescription,
    this.issueCategory,
  });

  @override
  List<Object?> get props => [userEmail, issueDescription, issueCategory];
}

class FetchMyTicketsRequested extends TicketingEvent {
  const FetchMyTicketsRequested();
}

class FetchTicketDetailsRequested extends TicketingEvent {
  final String ticketId;

  const FetchTicketDetailsRequested(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

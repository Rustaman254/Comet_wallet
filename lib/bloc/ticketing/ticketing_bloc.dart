import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/ticketing_service.dart';
import 'ticketing_event.dart';
import 'ticketing_state.dart';

class TicketingBloc extends Bloc<TicketingEvent, TicketingState> {
  TicketingBloc() : super(const TicketingState()) {
    on<CreateTicketRequested>(_onCreateTicketRequested);
    on<CreateGuestTicketRequested>(_onCreateGuestTicketRequested);
    on<FetchMyTicketsRequested>(_onFetchMyTicketsRequested);
    on<FetchTicketDetailsRequested>(_onFetchTicketDetailsRequested);
  }

  Future<void> _onCreateTicketRequested(
    CreateTicketRequested event,
    Emitter<TicketingState> emit,
  ) async {
    emit(state.copyWith(status: TicketingStatus.loading));
    try {
      final ticket = await TicketingService.createTicket(
        issueCategory: event.issueCategory,
        issueDescription: event.issueDescription,
      );
      emit(state.copyWith(
        status: TicketingStatus.success,
        successMessage: 'Ticket created successfully',
        currentTicket: ticket,
        tickets: [ticket, ...state.tickets],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateGuestTicketRequested(
    CreateGuestTicketRequested event,
    Emitter<TicketingState> emit,
  ) async {
    emit(state.copyWith(status: TicketingStatus.loading));
    try {
      final ticket = await TicketingService.createGuestTicket(
        userEmail: event.userEmail,
        issueDescription: event.issueDescription,
        issueCategory: event.issueCategory,
      );
      emit(state.copyWith(
        status: TicketingStatus.success,
        successMessage: 'Ticket created successfully',
        currentTicket: ticket,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFetchMyTicketsRequested(
    FetchMyTicketsRequested event,
    Emitter<TicketingState> emit,
  ) async {
    emit(state.copyWith(status: TicketingStatus.loading));
    try {
      final tickets = await TicketingService.getMyTickets();
      emit(state.copyWith(
        status: TicketingStatus.success,
        tickets: tickets,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFetchTicketDetailsRequested(
    FetchTicketDetailsRequested event,
    Emitter<TicketingState> emit,
  ) async {
    emit(state.copyWith(status: TicketingStatus.loading));
    try {
      final ticket = await TicketingService.getTicketById(event.ticketId);
      emit(state.copyWith(
        status: TicketingStatus.success,
        currentTicket: ticket,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}

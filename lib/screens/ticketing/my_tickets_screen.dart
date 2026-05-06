import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../bloc/ticketing/ticketing_bloc.dart';
import '../../bloc/ticketing/ticketing_event.dart';
import '../../bloc/ticketing/ticketing_state.dart';
import '../../constants/colors.dart';
import '../../models/ticket.dart';
import 'ticket_details_screen.dart';
import 'create_ticket_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketingBloc>().add(const FetchMyTicketsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : lightPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Support Tickets',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightPrimaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: HeroIcon(
              HeroIcons.plusCircle,
              color: primaryBrandColor,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TicketingBloc, TicketingState>(
        builder: (context, state) {
          if (state.status == TicketingStatus.loading && state.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TicketingStatus.failure && state.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(HeroIcons.exclamationCircle, size: 64, color: Colors.red.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load tickets',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white70 : lightSecondaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<TicketingBloc>().add(const FetchMyTicketsRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(
                    HeroIcons.ticket,
                    size: 80,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tickets found',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Have an issue? Raise a ticket and we\'ll help.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: isDark ? Colors.white38 : lightTertiaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TicketingBloc>().add(const FetchMyTicketsRequested());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.tickets.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(context, state.tickets[index], isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket, bool isDark) {
    Color statusColor;
    switch (ticket.currentStatus) {
      case 'not_attended':
        statusColor = Colors.orange;
        break;
      case 'being_attended':
        statusColor = primaryBrandColor;
        break;
      case 'closed':
        statusColor = successGreen;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticketId: ticket.ticketId)),
        ).then((_) {
          // Refresh list when coming back
          context.read<TicketingBloc>().add(const FetchMyTicketsRequested());
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? darkSurface : lightCardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? darkBorder : lightBorder,
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.currentStatus.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  ticket.ticketId,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : lightTertiaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.issueCategory.isEmpty ? 'Support Request' : ticket.issueCategory,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : lightPrimaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.issueDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: isDark ? Colors.white70 : lightSecondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                HeroIcon(
                  HeroIcons.calendar,
                  size: 14,
                  color: isDark ? Colors.white38 : lightTertiaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(ticket.ticketCreatedOn),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: isDark ? Colors.white38 : lightTertiaryText,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? Colors.white38 : lightTertiaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

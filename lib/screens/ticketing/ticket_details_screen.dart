import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../bloc/ticketing/ticketing_bloc.dart';
import '../../bloc/ticketing/ticketing_event.dart';
import '../../bloc/ticketing/ticketing_state.dart';
import '../../constants/colors.dart';
import '../../models/ticket.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketingBloc>().add(FetchTicketDetailsRequested(widget.ticketId));
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
          'Ticket Details',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white : lightPrimaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TicketingBloc, TicketingState>(
        builder: (context, state) {
          if (state.status == TicketingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TicketingStatus.failure || state.currentTicket == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(HeroIcons.exclamationCircle, size: 64, color: Colors.red.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load ticket details',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white70 : lightSecondaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<TicketingBloc>().add(FetchTicketDetailsRequested(widget.ticketId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final ticket = state.currentTicket!;
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? darkSurface : lightCardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? darkBorder : lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ticket.currentStatus.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Text(
                            ticket.ticketId,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : lightTertiaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        ticket.issueCategory.isEmpty ? 'Support Request' : ticket.issueCategory,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket.issueDescription,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          color: isDark ? Colors.white70 : lightSecondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: isDark ? darkBorder : lightBorder),
                      const SizedBox(height: 24),
                      _buildInfoRow('Created On', DateFormat('MMMM dd, yyyy • HH:mm').format(ticket.ticketCreatedOn), HeroIcons.calendar, isDark),
                      const SizedBox(height: 16),
                      _buildInfoRow('Assigned To', ticket.assignedTo, HeroIcons.user, isDark),
                    ],
                  ),
                ),
                if (ticket.adminComments.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Admin Response',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryBrandColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryBrandColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      ticket.adminComments,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        color: isDark ? Colors.white : lightPrimaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, HeroIcons icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HeroIcon(
            icon,
            size: 16,
            color: isDark ? Colors.white38 : lightTertiaryText,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: isDark ? Colors.white38 : lightTertiaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : lightPrimaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

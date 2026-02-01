import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';

/// Reserve Seats Screen
class ReserveSeatsScreen extends ConsumerStatefulWidget {
  final String showId;

  const ReserveSeatsScreen({super.key, required this.showId});

  @override
  ConsumerState<ReserveSeatsScreen> createState() => _ReserveSeatsScreenState();
}

class _ReserveSeatsScreenState extends ConsumerState<ReserveSeatsScreen> {
  int _selectedSeats = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final showAsync = ref.watch(showDetailProvider(int.parse(widget.showId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver des places'),
      ),
      body: showAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(error.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(showDetailProvider(int.parse(widget.showId))),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (show) {
          final maxSeats = show.availableSeats.clamp(0, 4);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tv, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              show.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${show.availableSeats} places disponibles',
                              style: TextStyle(
                                color: show.isSoldOut ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Seat Selection
                const Text(
                  'Nombre de places',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Maximum 4 places par réservation',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // Seat Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _selectedSeats > 1
                            ? () => setState(() => _selectedSeats--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 40,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text(
                            '$_selectedSeats',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedSeats == 1 ? 'place' : 'places',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: _selectedSeats < maxSeats
                            ? () => setState(() => _selectedSeats++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 40,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre demande sera examinée par notre équipe. Vous recevrez une notification une fois approuvée.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || maxSeats == 0
                        ? null
                        : () => _submitReservation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmer la réservation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReservation(BuildContext context) async {
    // Capture navigator and scaffold messenger before async gap
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);

    try {
      await ref.read(myReservationsProvider.notifier).createReservation(
            showId: int.parse(widget.showId),
            seats: _selectedSeats,
          );

      if (!mounted) return;
      router.go(Routes.reservationSuccess);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

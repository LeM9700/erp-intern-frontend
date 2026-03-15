import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';
import 'package:erp_frontend/features/attendance/presentation/providers/attendance_provider.dart';

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveAttendanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Présences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(liveAttendanceProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(liveAttendanceProvider),
        child: liveAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Aucun stagiaire présentement pointé',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) =>
                  _AttendanceCard(session: sessions[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Erreur: $e'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(liveAttendanceProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  final LiveAttendanceModel session;

  const _AttendanceCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            session.userFullName.isNotEmpty
                ? session.userFullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(session.userFullName,
            style: theme.textTheme.titleMedium),
        subtitle: Text(
          'Arrivé à ${_formatTime(session.createdAt)}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge "Présent"
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Présent',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton photo
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined),
              tooltip: 'Voir la photo de pointage',
              onPressed: () => _showPhoto(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context, WidgetRef ref) {
    final dio = ref.read(dioProvider);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.userFullName,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    'Arrivé à ${_formatTime(session.createdAt)}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _PhotoViewer(
              dio: dio,
              photoUrl:
                  '${ApiConstants.baseUrl}/files/${session.clockInPhotoId}/view',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Fetches and displays a photo using Dio (handles auth token automatically).
class _PhotoViewer extends StatefulWidget {
  final Dio dio;
  final String photoUrl;

  const _PhotoViewer({required this.dio, required this.photoUrl});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchBytes();
  }

  Future<Uint8List> _fetchBytes() async {
    final response = await widget.dio.get<List<int>>(
      widget.photoUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 48),
                  SizedBox(height: 8),
                  Text('Impossible de charger la photo'),
                ],
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../ui/widgets/sf_card.dart';
import '../../core/session/session_provider.dart';
import 'hall_interior_screen.dart'; // hallBySlugProvider, isSubscribedProvider

class _ChatMessage {
  final String displayName;
  final String role; // 'creator' | 'subscriber' | 'admin'
  final String body;
  final DateTime createdAt;

  _ChatMessage({
    required this.displayName,
    required this.role,
    required this.body,
    required this.createdAt,
  });
}

class HallChatTab extends ConsumerStatefulWidget {
  final String slug;

  const HallChatTab({super.key, required this.slug});

  @override
  ConsumerState<HallChatTab> createState() => _HallChatTabState();
}

class _HallChatTabState extends ConsumerState<HallChatTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  RealtimeChannel? _channel;
  bool _sending = false;
  String? _subscribedHallId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final hall = await ref.read(hallBySlugProvider(widget.slug).future);
      if (hall != null && mounted) {
        _subscribeToChat(hall['id'] as String);
      }
    } catch (_) {}
  }

  void _subscribeToChat(String hallId) {
    if (_subscribedHallId == hallId) return;
    _subscribedHallId = hallId;
    _channel = Supabase.instance.client.channel(
      'hall_chat_$hallId',
      opts: const RealtimeChannelConfig(self: true),
    )
      ..onBroadcast(
        event: 'chat_message',
        callback: (payload) {
          if (!mounted) return;
          final msg = _ChatMessage(
            displayName: payload['display_name'] as String? ?? 'Anonymous',
            role: payload['role'] as String? ?? 'subscriber',
            body: payload['body'] as String? ?? '',
            createdAt: DateTime.tryParse(payload['created_at'] as String? ?? '') ?? DateTime.now(),
          );
          setState(() => _messages.add(msg));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending || _channel == null) return;

    final session = ref.read(sessionProvider);
    setState(() => _sending = true);
    _messageController.clear();

    await _channel!.sendBroadcastMessage(
      event: 'chat_message',
      payload: {
        'display_name': session.displayName ?? 'Anonymous',
        'role': session.role ?? 'subscriber',
        'body': body,
        'created_at': DateTime.now().toIso8601String(),
      },
    );

    setState(() => _sending = false);
  }

  Color _nameColor(String role) {
    if (role == 'creator') return SFColors.gold;
    return SFColors.creamMuted;
  }

  @override
  Widget build(BuildContext context) {
    final hallAsync = ref.watch(hallBySlugProvider(widget.slug));
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: SFColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat'),
        backgroundColor: SFColors.charcoal,
      ),
      body: hallAsync.when(
        data: (hall) {
          if (hall == null) {
            return const Center(child: Text('Hall not found'));
          }

          final hallId = hall['id'] as String;
          final isSubscribedAsync = session.isAuthenticated && session.userId != null
              ? ref.watch(isSubscribedProvider('${session.userId!}_$hallId'))
              : const AsyncValue.data(false);

          final creators = hall['creators'] as List<dynamic>?;
          final creatorProfileId = creators?.isNotEmpty == true
              ? creators![0]['profile_id'] as String?
              : null;
          final isCreator = session.userId != null && creatorProfileId == session.userId;

          return isSubscribedAsync.when(
            data: (isSubscribed) {
              if (!isCreator && !isSubscribed) {
                return Center(
                  child: SFCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 48, color: SFColors.gold),
                        const SizedBox(height: 16),
                        Text(
                          'Subscribe to access chat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join this hall to participate in the conversation',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Be the first to say something',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: SFColors.creamMuted),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final msg = _messages[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: _nameColor(msg.role),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.body,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SFColors.charcoal,
                      border: Border(
                        top: BorderSide(color: SFColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: SFColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _sending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SFColors.gold,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: SFColors.gold),
                                onPressed: _sendMessage,
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

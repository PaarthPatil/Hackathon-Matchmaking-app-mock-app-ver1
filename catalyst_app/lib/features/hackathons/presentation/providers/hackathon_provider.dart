import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/features/hackathons/data/hackathon_repository.dart';

class HackathonState {
  final List<Hackathon> items;
  final bool isLoading;
  final bool isListLoading; 
  final String? error;
  final int offset;
  final bool hasMore;

  HackathonState({
    required this.items,
    this.isLoading = false,
    this.isListLoading = false,
    this.error,
    this.offset = 0,
    this.hasMore = true,
  });

  factory HackathonState.initial() => HackathonState(items: []);

  HackathonState copyWith({
    List<Hackathon>? items,
    bool? isLoading,
    bool? isListLoading,
    String? error,
    int? offset,
    bool? hasMore,
  }) {
    return HackathonState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      error: error ?? this.error,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HackathonNotifier extends StateNotifier<HackathonState> {
  final HackathonRepository _repository;
  static const int _limit = 10;

  HackathonNotifier(this._repository) : super(HackathonState.initial()) {
    fetchHackathons();
  }

  Future<void> fetchHackathons({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(items: [], offset: 0, hasMore: true, isLoading: true);
    } else if (state.items.isEmpty) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isListLoading: true);
    }

    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 600));
      final newItems = List.generate(20, (index) => Hackathon(
          id: 'hack-$index',
          title: 'Catalyst Elite Hackathon ${index + 1}',
          description: 'A premium, gamified global competition. Big prizes and insane matching algorithms. Build apps of the future.',
          mode: index % 2 == 0 ? 'Online' : 'In-Person',
          location: index % 2 == 0 ? null : 'Silicon Valley, CA',
          tags: index % 3 == 0 ? ['AI', 'Web3', 'Blockchain'] : ['Flutter', 'Supabase', 'Design'],
          prizePool: '\$${(index + 1) * 10},000',
          startDate: DateTime.now().add(Duration(days: index * 2)),
          endDate: DateTime.now().add(Duration(days: index * 2 + 3)),
      ));
      
      state = state.copyWith(
        items: refresh ? newItems : [...state.items, ...newItems],
        isLoading: false,
        isListLoading: false,
        offset: state.offset + newItems.length,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        isListLoading: false, 
        error: e.toString()
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isListLoading || !state.hasMore) return;
    await fetchHackathons();
  }
}

final hackathonRepositoryProvider = Provider((ref) => HackathonRepository());

final hackathonProvider = StateNotifierProvider<HackathonNotifier, HackathonState>((ref) {
  return HackathonNotifier(ref.read(hackathonRepositoryProvider));
});

final hackathonByIdProvider = FutureProvider.family<Hackathon, String>((ref, id) async {
  // PROTOTYPE MOCK
  await Future.delayed(const Duration(milliseconds: 300));
  return Hackathon(
    id: id,
    title: 'Global AI Web3 Hackathon',
    description: 'Build the decentralised AI future.',
    mode: 'Online',
    tags: ['AI', 'Web3', 'Blockchain'],
    prizePool: '\$50,000',
    startDate: DateTime.now().add(const Duration(days: 4)),
    endDate: DateTime.now().add(const Duration(days: 8)),
  );
});

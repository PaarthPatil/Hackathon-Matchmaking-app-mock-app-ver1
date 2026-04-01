import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/hackathon_model.dart';
import 'package:catalyst_app/features/hackathons/data/hackathon_repository.dart';

class HackathonState {
  static const Object _noErrorChange = Object();
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
    Object? error = _noErrorChange,
    int? offset,
    bool? hasMore,
  }) {
    return HackathonState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      error: identical(error, _noErrorChange) ? this.error : error as String?,
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
    final currentOffset = refresh ? 0 : state.offset;
    if (refresh) {
      state = state.copyWith(items: [], offset: 0, hasMore: true, isLoading: true);
    } else if (state.items.isEmpty) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isListLoading: true);
    }

    try {
      final newItems = await _repository.fetchHackathons(
        limit: _limit,
        offset: currentOffset,
      );
      final mergedItems = refresh ? newItems : [...state.items, ...newItems];
      state = state.copyWith(
        items: mergedItems,
        isLoading: false,
        isListLoading: false,
        error: null,
        offset: mergedItems.length,
        hasMore: newItems.length >= _limit,
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
  return ref.read(hackathonRepositoryProvider).fetchHackathonById(id);
});

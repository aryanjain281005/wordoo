import 'package:flutter/material.dart';
import '../data/lang.dart';
import '../models/models.dart';
import '../widgets/item_views.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'spelling_hive/spelling_hive.dart';
import 'story_quest/story_quest.dart';

/// Everything a game needs to show ONE item. The shared GameHost (game_screen.dart) owns the quest,
/// the learner model, rewards and story; a game module only turns an item into play.
class GameCtx {
  final Item item;
  final bool scaffold;
  final LangPack pack;
  final bool demo;
  final void Function(String msg, bool good) feedback;
  final void Function(ItemResult r) done;
  const GameCtx({required this.item, required this.scaffold, required this.pack, required this.feedback, required this.done, this.demo = false});
}

typedef GameItemBuilder = Widget Function(BuildContext context, GameCtx ctx, Key key);

/// Registry: which widget plays which game. Games without a dedicated module use the classic item view.
class GameModules {
  static final Map<GameId, GameItemBuilder> _registry = {
    GameId.spellingHive: (c, ctx, key) => SpellingHiveItem(key: key, ctx: ctx, hiveBees: _state(c)?.hiveBees ?? 0),
    GameId.storyQuest: (c, ctx, key) => StoryQuestItem(key: key, ctx: ctx, libraryBooks: _state(c)?.libraryBooks.length ?? 0),
  };

  static AppState? _state(BuildContext c) {
    try {
      return Provider.of<AppState>(c, listen: false);
    } catch (_) {
      return null; // used outside the app (tests, previews)
    }
  }

  static GameItemBuilder of(GameId id) => _registry[id] ?? _classic;
  static bool hasDedicated(GameId id) => _registry.containsKey(id);

  static Widget _classic(BuildContext c, GameCtx ctx, Key key) => ItemView(
        key: key,
        item: ctx.item,
        skin: skinFor(ctx.item.skill),
        pack: ctx.pack,
        scaffold: ctx.scaffold,
        demo: ctx.demo,
        onFeedback: ctx.feedback,
        onDone: ctx.done,
      );
}

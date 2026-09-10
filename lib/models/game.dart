import 'package:flutter/foundation.dart';

class Friend {
  final String name;
  final int level;
  final bool online;
  const Friend(this.name, this.level, this.online);
}

class ActionCard {
  final String rank;
  final String suit;
  final int power;
  const ActionCard(this.rank, this.suit, this.power);
  String get description => suit;
}

/// Mesa recreativa: fichas são pontos internos, sem compra ou valor monetário.
class DemoGame extends ChangeNotifier {
  final int playerCount;
  DemoGame({this.playerCount = 4}) : chips = List.filled(playerCount, 1000);
  final List<int> chips;
  final List<ActionCard> hand = [
    const ActionCard('A', '♦', 0),
    const ActionCard('A', '♥', 0),
  ];
  final List<ActionCard> community = [
    const ActionCard('10', '♠', 0),
    const ActionCard('J', '♥', 0),
    const ActionCard('Q', '♣', 0),
    const ActionCard('7', '♦', 0),
    const ActionCard('3', '♣', 0),
  ];
  int round = 0,
      current = 0,
      selected = 0,
      pot = 0,
      chipsToCall = 20,
      revealed = 0;
  bool finished = false;
  String message = 'Sua vez · escolha uma ação';
  bool get canAct => !finished && current == 0;
  List<ActionCard> get visibleCommunity => community.take(revealed).toList();
  void select(int i) {
    if (i >= 0 && i < hand.length) {
      selected = i;
      notifyListeners();
    }
  }

  void fold() {
    if (!canAct) return;
    finished = true;
    message = 'Você desistiu da mão';
    notifyListeners();
  }

  void check() {
    if (!canAct) return;
    message = 'Você passou';
    _next();
  }

  void call() {
    if (!canAct) return;
    final a = chipsToCall.clamp(0, chips[0]);
    chips[0] -= a;
    pot += a;
    message = 'Você pagou $a fichas';
    _next();
  }

  void raise(int amount) {
    if (!canAct) return;
    final a = (chipsToCall + amount).clamp(0, chips[0]);
    chips[0] -= a;
    pot += a;
    chipsToCall = a;
    message = 'Você aumentou para $a fichas';
    _next();
  }

  void _next() {
    current++;
    if (current >= playerCount) {
      current = 0;
      round++;
      if (revealed < 5) revealed++;
      if (round >= 5) {
        finished = true;
        chips[0] += pot;
        message = 'Mão encerrada · pote: $pot fichas';
      } else {
        chipsToCall = 20;
        message = 'Sua vez · carta comunitária revelada';
      }
    }
    notifyListeners();
  }
}

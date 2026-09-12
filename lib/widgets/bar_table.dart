import 'package:flutter/material.dart';

const barTableNames = {
  'table-0': 'Floresta',
  'table-1': 'Noite',
  'table-2': 'Boteco Clássico',
  'table-3': 'Bar da Praia',
  'table-4': 'Madeira Imperial',
  'table-5': 'Quiosque da Praia',
  'table-6': 'Taverna da Serra',
};

String barTableAsset(String table) => switch (table) {
  'table-3' || 'table-5' => 'assets/images/table-praia.png',
  'table-4' || 'table-6' => 'assets/images/table-serra.png',
  _ => 'assets/images/truco-br-bar-table.png',
};

class BarTable extends StatelessWidget {
  final String table;
  const BarTable({super.key, this.table = 'table-2'});
  @override
  Widget build(BuildContext context) =>
      Image.asset(barTableAsset(table), fit: BoxFit.cover);
}

class CharacterPortrait extends StatelessWidget {
  final int index;
  final double size;
  const CharacterPortrait({super.key, required this.index, required this.size});
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: size * 3,
        maxHeight: size * 2,
        child: Transform.translate(
          offset: Offset(-(index % 3) * size, -(index ~/ 3) * size),
          child: Image.asset(
            'assets/images/truco-br-characters.png',
            width: size * 3,
            height: size * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    ),
  );
}

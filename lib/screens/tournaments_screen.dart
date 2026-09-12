part of '../core/app.dart';

extension _Tournaments on _AuroraAppState {
  Future<void> showTournamentMatchPrompt() async {
    if (!mounted) return;
    final play = await showDialog<bool>(
      context: navigator.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sua partida está pronta'),
        content: const Text(
          'Entre na mesa do torneio em até 1min35s. Se o prazo terminar, você perderá por WO.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('DEPOIS'),
          ),
          GameButton(
            'JOGAR AGORA',
            color: green,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (play == true && mounted) {
      refreshUI(() => screen = 'match');
      orient(true);
    }
  }

  Future<void> enrollTournament(Map<String, dynamic> t) async {
    final joined = (t['players'] as List).contains(uid);
    final body = <String, dynamic>{
      'id': t['id'],
      'action': joined ? 'leave' : 'join',
    };
    if (!joined && t['mode'] == '2v2') {
      final code = TextEditingController();
      String action = 'create';
      final choice = await showDialog<Map<String, dynamic>>(
        context: navigator.currentContext!,
        builder: (c) => StatefulBuilder(
          builder: (c, update) => AlertDialog(
            title: const Text('Escolha sua dupla'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'create',
                        label: Text('Criar Código'),
                      ),
                      ButtonSegment(
                        value: 'join',
                        label: Text('Entrar em Código'),
                      ),
                    ],
                    selected: {action},
                    onSelectionChanged: (v) => update(() => action = v.first),
                  ),
                  const SizedBox(height: 16),
                  if (action == 'join')
                    TextField(
                      controller: code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código da dupla',
                      ),
                    )
                  else
                    const Text(
                      'Crie sua dupla e compartilhe o código com seu parceiro. Vocês jogarão juntos até o final.',
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Você pode jogar salas antes do início. No horário, elas serão encerradas sem resultado e as entradas serão devolvidas.',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancelar'),
              ),
              GameButton(
                'INSCREVER',
                onPressed: () => Navigator.pop(c, {
                  'team_action': action,
                  'team_code': code.text.trim().toUpperCase(),
                }),
              ),
            ],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      code.dispose();
      if (choice == null || !mounted) return;
      body.addAll(choice);
    }
    await mutation('tournaments', body, reload: true);
    if (!joined && t['mode'] == '2v2' && mounted) {
      final matches = (extra['tournaments'] as List? ?? []).where(
        (x) => x['id'] == t['id'],
      );
      if (matches.isNotEmpty && matches.first['team_code'] != null) {
        await showTeamCode(matches.first['team_code']);
      }
    }
  }

  Future<void> showTeamCode(String code) => showDialog<void>(
    context: navigator.currentContext!,
    builder: (c) => AlertDialog(
      title: const Text('Código da sua dupla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 28,
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Seu parceiro deve escolher Entrar em Código neste torneio.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            message('Código copiado.');
          },
          child: const Text('Copiar'),
        ),
        GameButton('FECHAR', onPressed: () => Navigator.pop(c)),
      ],
    ),
  );
  String tournamentDate(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return 'Ao completar as vagas';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} às ${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> respondInvite(dynamic invite, bool accept) async {
    await run(() async {
      final result = await api.request('api/invite/respond', {
        'id': invite['id'],
        'action': accept ? 'accept' : 'decline',
      });
      if (!mounted) return;
      if (accept) navigator.currentState?.popUntil((route) => route.isFirst);
      refreshUI(() {
        hiddenInvites.add(invite['id']);
        if (accept) {
          room = result;
          screen = 'lobby';
          orient(false);
        }
      });
      await api.refresh();
    });
  }

  Future<void> createTournament() async {
    tournamentNameInput.clear();
    final slots = TextEditingController(text: '16');
    final prizeInput = TextEditingController(text: '4000');
    final phraseInput = TextEditingController(text: 'TRUCO BR');
    String table = 'table-2';
    String mode = '1v1';
    int entryFee = 0;
    DateTime? start;
    String? error;
    final result = await showDialog<Map<String, dynamic>>(
      context: navigator.currentContext!,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Criar torneio'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tournamentNameInput,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Nome do torneio',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: '1v1',
                        label: Text('Individual • 1v1'),
                      ),
                      ButtonSegment(value: '2v2', label: Text('Duplas • 2v2')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => update(() => mode = v.first),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: entryFee,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de inscrição (fichas)',
                    ),
                    items: const [0, 100, 500, 1000, 5000, 10000]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value == 0 ? 'Grátis' : '$value fichas',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => update(() => entryFee = value ?? 0),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: slots,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Vagas de jogadores',
                      helperText: '2 a 256 • duplas: número par, mínimo 4',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month, color: gold),
                    title: const Text('Horário de início'),
                    subtitle: Text(
                      start == null
                          ? 'Toque para escolher a data e o horário'
                          : tournamentDate(start!.toIso8601String()),
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(hours: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          start ?? DateTime.now().add(const Duration(hours: 1)),
                        ),
                      );
                      if (time != null && context.mounted) {
                        update(
                          () => start = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    },
                  ),
                  const Text(
                    'Começa no horário com os inscritos, mesmo sem lotar. Duplas se unem por código. Só duplas completas entram na chave. Mínimo: 2 jogadores (1v1) ou 4 (2v2). Salas casuais serão encerradas no início, devolvendo as entradas.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: table,
                    decoration: const InputDecoration(
                      labelText: 'Mesa do torneio',
                    ),
                    items: [
                      for (final entry in barTableNames.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (value) => update(() => table = value!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 110,
                      width: 90,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BarTable(table: table),
                      ),
                    ),
                  ),
                  TextField(
                    controller: phraseInput,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Escrever na mesa',
                    ),
                  ),
                  TextField(
                    controller: prizeInput,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Premiação total em fichas',
                      helperText: '0 a 1.000.000 • valor par para duplas',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            GameButton(
              'PUBLICAR',
              color: gold,
              onPressed: () {
                final n = int.tryParse(slots.text) ?? 0;
                final prize = int.tryParse(prizeInput.text) ?? -1;
                if (tournamentNameInput.text.trim().length < 3 ||
                    n < 2 ||
                    n > 256 ||
                    (mode == '2v2' && (n < 4 || n.isOdd)) ||
                    start == null ||
                    !start!.isAfter(DateTime.now()) ||
                    prize < 0 ||
                    prize > 1000000 ||
                    (mode == '2v2' && prize.isOdd)) {
                  update(
                    () => error = 'Confira nome, vagas e um horário futuro.',
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': tournamentNameInput.text.trim(),
                  'size': n,
                  'mode': mode,
                  'starts_at': start!.toUtc().toIso8601String(),
                  'entry_fee': entryFee,
                  'table': table,
                  'table_text': phraseInput.text.trim(),
                  'prize': prize,
                });
              },
            ),
          ],
        ),
      ),
    );
    // Wait until the dialog route has finished its closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    slots.dispose();
    prizeInput.dispose();
    phraseInput.dispose();
    if (result != null && mounted) {
      refreshUI(() => tournamentTab = 1);
      await run(() async {
        final response = await api.request('api/tournaments/create', result);
        if (!mounted) return;
        final created = response['created'] as Map?;
        if (created != null) knownTournaments.add(created['id'].toString());
        refreshUI(() => extra = response);
        await api.refresh();
        if (mounted) {
          await showDialog<void>(
            context: navigator.currentContext!,
            builder: (c) => AlertDialog(
              title: const Text('Torneio criado!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TournamentTrophy(size: 80),
                  Text(result['name'], style: const TextStyle(fontSize: 22)),
                  Text(tournamentDate(result['starts_at'])),
                  Text('${result['mode']} • ${result['size']} vagas'),
                  Text(
                    '${number(result['prize'])} fichas',
                    style: const TextStyle(color: gold),
                  ),
                ],
              ),
              actions: [
                GameButton('PRONTO', onPressed: () => Navigator.pop(c)),
              ],
            ),
          );
        }
      });
    }
  }

  Future<void> deleteTournament(Map<String, dynamic> t) async {
    final confirmed = await showDialog<bool>(
      context: navigator.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Excluir torneio?'),
        content: Text(
          'O torneio "${t['name']}" será removido da lista. As inscrições serão encerradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          GameButton(
            'EXCLUIR',
            color: Colors.redAccent,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await mutation('tournaments', {
      'id': t['id'],
      'action': 'delete',
    }, reload: true);
    if (mounted) message('Torneio excluído.');
  }

  Future<void> showChampion(Map<String, dynamic> t) => showDialog<void>(
    context: navigator.currentContext!,
    builder: (context) => AlertDialog(
      backgroundColor: ink,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TournamentTrophy(size: 104),
            const Text(
              'CAMPEÃO!',
              style: TextStyle(
                color: gold,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t['name'] ?? 'Torneio',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 8,
              children: [
                for (final id in t['champions'] as List? ?? [uid])
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatar(
                        id == uid ? playerName : entrantName(id),
                        size: 56,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        id == uid ? playerName : entrantName(id),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${t['mode'] ?? '1v1'} • ${tournamentDate(t['date'])}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '+${number(t['chips'])} fichas   +${t['xp'] ?? 1000} XP',
              style: const TextStyle(color: gold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Título salvo no seu perfil.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
      actions: [
        GameButton(
          'CONTINUAR',
          color: gold,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  Widget tournamentsScreen() {
    final all = extra['tournaments'] as List? ?? [];
    final filtered = all
        .where(
          (t) => switch (tournamentTab) {
            0 => t['status'] == 'playing',
            1 => t['status'] == 'waiting',
            2 => (t['players'] as List).contains(uid),
            _ => ['finished', 'cancelled'].contains(t['status']),
          },
        )
        .toList()
        .reversed
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PlayerAvatar(playerName, size: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Nível ${me['level']} • ${me['xp']} XP',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => go('wallet'),
              icon: const Icon(Icons.monetization_on, color: gold),
              label: Text(
                number(api.data['chips']),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/truco-br-tournaments.png'),
                fit: BoxFit.cover,
                opacity: .85,
              ),
              gradient: LinearGradient(colors: [Color(0xFF483019), ink]),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TORNEIOS',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'DISPUTE, EVOLUA E MOSTRE\nSEU TRUCO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final entry in [
              'Em andamento',
              'Próximos',
              'Meus torneios',
              'Histórico',
            ].asMap().entries)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: entry.key == 3 ? 0 : 4),
                  child: SizedBox(
                    height: 42,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        backgroundColor: tournamentTab == entry.key
                            ? gold
                            : panelColor,
                        foregroundColor: tournamentTab == entry.key
                            ? ink
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF36554E)),
                        ),
                      ),
                      onPressed: () =>
                          refreshUI(() => tournamentTab = entry.key),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (api.data['can_create_tournaments'] == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: GameButton(
              'CRIAR TORNEIO',
              color: gold,
              icon: Icons.add,
              onPressed: busy ? null : createTournament,
            ),
          ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          empty(
            all.isEmpty
                ? 'Nenhum torneio publicado. Os eventos criados pelo administrador aparecerão aqui.'
                : 'Nenhum torneio nesta categoria.',
            Icons.emoji_events_outlined,
          ),
        for (final t in filtered) tournamentCard(Map<String, dynamic>.from(t)),
        TextButton.icon(
          onPressed: busy ? null : () => go('tournaments'),
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar torneios'),
        ),
      ],
    );
  }

  String entrantName(dynamic entrant) => (entrant is List ? entrant : [entrant])
      .map(
        (id) => extra['names']?[id] ?? api.data['tournament_names']?[id] ?? id,
      )
      .join(' + ');

  Widget tournamentCard(Map<String, dynamic> t) {
    final waiting = t['status'] == 'waiting';
    final playing = t['status'] == 'playing';
    final joined = (t['players'] as List).contains(uid);
    final full = (t['players'] as List).length >= t['size'];
    final accent = playing
        ? gold
        : waiting
        ? const Color(0xFFB5CED2)
        : const Color(0xFFDE9453);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TrucoPanel(
        padding: const EdgeInsets.all(10),
        color: playing ? const Color(0xFF054737) : const Color(0xFF14302D),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: .2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TournamentTrophy(size: 64, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['name'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playing
                            ? '● AO VIVO'
                            : waiting
                            ? 'INSCRIÇÕES ABERTAS'
                            : t['status'] == 'finished'
                            ? 'ENCERRADO'
                            : 'CANCELADO',
                        style: TextStyle(
                          fontSize: 10,
                          color: playing ? Colors.redAccent : gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${(t['players'] as List).length}/${t['size']} jogadores',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            t['mode'] ?? '1v1',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            (t['entry_fee'] ?? 0) == 0
                                ? 'Grátis'
                                : 'Entrada: ${number(t['entry_fee'])}',
                            style: const TextStyle(fontSize: 11, color: gold),
                          ),
                          const Text(
                            'Truco Paulista',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        waiting
                            ? 'Início: ${tournamentDate(t['starts_at'])}'
                            : playing
                            ? 'Rodada ${(t['rounds'] as List).length}'
                            : t['reason'] ??
                                  'Campeão: ${entrantName(t['winner'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (api.data['can_create_tournaments'] == true &&
                    t['created_by'] == uid &&
                    !playing)
                  IconButton(
                    tooltip: 'Excluir torneio',
                    onPressed: busy ? null : () => deleteTournament(t),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            if ((t['unpaired'] as List? ?? []).contains(uid))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Você ficou sem dupla nesta edição e não entrou na chave.',
                  style: TextStyle(color: gold),
                ),
              ),
            const SizedBox(height: 8),
            if (joined && waiting && t['team_code'] != null)
              TextButton.icon(
                onPressed: () => showTeamCode(t['team_code']),
                icon: const Icon(Icons.group, color: gold),
                label: Text('Código da dupla: ${t['team_code']}'),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: accent.withValues(alpha: .5)),
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C3512), ink],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waiting ? 'Premiação máxima' : 'Premiação total',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          '${number(t['prize'] ?? t['custom_prize'] ?? t['size'] * 250)} fichas',
                          style: const TextStyle(
                            color: gold,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (waiting)
                    GameButton(
                      joined
                          ? 'CANCELAR'
                          : full
                          ? 'LOTADO'
                          : 'ENTRAR',
                      color: joined ? panelColor : green,
                      onPressed: busy || (full && !joined)
                          ? null
                          : () => enrollTournament(t),
                    )
                  else
                    GameButton(
                      playing ? 'ACOMPANHAR' : 'RESULTADO',
                      color: playing ? gold : panelColor,
                      onPressed: () => showBracket(t),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showBracket(Map<String, dynamic> original) => showDialog<void>(
    context: navigator.currentContext!,
    builder: (context) => AnimatedBuilder(
      animation: api,
      builder: (context, _) {
        final current = (api.data['tournaments'] as List? ?? []).where(
          (t) => t['id'] == original['id'],
        );
        final t = current.isEmpty ? original : current.first;
        final rounds = t['rounds'] as List;
        final total = rounds.isEmpty
            ? 0
            : rounds.first.length == 1
            ? 1
            : (rounds.first.length as int).bitLength;
        final height = rounds.isEmpty
            ? 240.0
            : (rounds.first.length * 124.0).clamp(240.0, 20000.0);
        return Dialog.fullscreen(
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    t['name'],
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '${t['mode']} • ${tournamentDate(t['starts_at'])}',
                  ),
                  trailing: const Icon(Icons.emoji_events, color: gold),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t['status'] == 'finished'
                        ? 'CAMPEÃO: ${entrantName(t['winner'])}'
                        : t['status'] == 'cancelled'
                        ? t['reason'] ?? 'Cancelado'
                        : 'CHAVEAMENTO • arraste para acompanhar',
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (rounds.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('A chave será formada no início do torneio.'),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          height: height + 40,
                          child: CustomPaint(
                            painter: BracketLines(rounds.first.length, total),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int r = 0; r < total; r++)
                                  SizedBox(
                                    width: 252,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 40,
                                          child: Center(
                                            child: Text(
                                              r == total - 1
                                                  ? 'FINAL'
                                                  : r == total - 2
                                                  ? 'SEMIFINAL'
                                                  : 'RODADA ${r + 1}',
                                              style: const TextStyle(
                                                color: gold,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              for (
                                                int m = 0;
                                                m <
                                                    ((rounds.first.length
                                                            as int) >>
                                                        r);
                                                m++
                                              )
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                            ),
                                                        child: bracketMatch(
                                                          r < rounds.length &&
                                                                  m <
                                                                      rounds[r]
                                                                          .length
                                                              ? Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(
                                                                  rounds[r][m],
                                                                )
                                                              : null,
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                    if (r < total - 1)
                                                      const SizedBox(
                                                        width: 16,
                                                        child: Divider(
                                                          color: gold,
                                                          thickness: 2,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget bracketMatch(Map<String, dynamic>? match, BuildContext dialogContext) {
    final teams =
        match?['teams'] as List? ??
        (match == null ? [null, null] : [match['players'], null]);
    return TrucoPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < teams.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    match?['winner'] != null &&
                            entrantName(teams[i]) ==
                                entrantName(match!['winner'])
                        ? Icons.emoji_events
                        : Icons.person_outline,
                    size: 18,
                    color: gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teams[i] == null ? 'A definir' : entrantName(teams[i]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match?['scores'] != null)
                    Text(
                      '${match!['scores'][i]}',
                      style: const TextStyle(color: gold),
                    ),
                ],
              ),
            ),
          if (match?['bye'] == true)
            const Text(
              'Folga • avanço automático',
              style: TextStyle(fontSize: 10, color: gold),
            ),
          if (match != null && match['room'] != null && match['winner'] == null)
            TextButton.icon(
              icon: const Icon(Icons.visibility, size: 16),
              label: Text(
                (match['players'] as List).contains(uid)
                    ? 'JOGAR AGORA'
                    : 'ASSISTIR AO VIVO',
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if ((match['players'] as List).contains(uid)) {
                  await enterRoom('state', {'code': match['room']});
                } else {
                  await run(() async {
                    await api.spectate(match['room']);
                    if (mounted) {
                      refreshUI(() {
                        room = Map<String, dynamic>.from(api.spectatedRoom!);
                        screen = 'match';
                      });
                    }
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}

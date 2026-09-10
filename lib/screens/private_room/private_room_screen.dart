part of '../../core/app.dart';

extension _PrivateRoomScreen on _AuroraAppState {
  Widget privateRoomScreen() => Row(
    children: [
      Expanded(
        child: GoldPanel(
          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('CRIAR SALA', size: 48),
              label('NOME DA SALA'),
              TextField(
                controller: roomNameInput,
                maxLength: 32,
                style: royalText(38),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Nome da sala',
                ),
              ),
              label('JOGADORES'),
              DropdownButtonFormField<int>(
                initialValue: capacity,
                style: royalText(36),
                dropdownColor: navy,
                items: [2, 3, 4]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: busy ? null : (v) => refresh(() => capacity = v!),
              ),
              const Spacer(),
              Row(
                children: [
                  Text('SOMENTE CONVIDADOS', style: royalText(29)),
                  const Spacer(),
                  Transform.scale(
                    scale: 1.5,
                    child: Switch(
                      value: private,
                      onChanged: busy
                          ? null
                          : (v) => refresh(() => private = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 103,
                child: RoyalButton(
                  label: busy ? 'AGUARDE…' : 'CRIAR SALA',
                  icon: Icons.person_add,
                  greenButton: true,
                  onPressed: busy ? null : () => submitRoom(false),
                  fontSize: 44,
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(
        width: 76,
        child: Column(
          children: [
            const Expanded(child: VerticalDivider(color: gold)),
            const Icon(Icons.workspace_premium, color: gold, size: 55),
            const Expanded(child: VerticalDivider(color: gold)),
          ],
        ),
      ),
      Expanded(
        child: GoldPanel(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          child: Column(
            children: [
              const SectionTitle('ENTRAR EM SALA', size: 45),
              const Spacer(),
              Text('CÓDIGO DA SALA', style: royalText(36)),
              const SizedBox(height: 30),
              CodeEntry(controller: codeInput),
              const SizedBox(height: 24),
              Text('DIGITE O CÓDIGO', style: royalText(29, color: muted)),
              const Spacer(),
              SizedBox(
                height: 103,
                child: RoyalButton(
                  label: busy ? 'AGUARDE…' : 'ENTRAR',
                  icon: Icons.login,
                  onPressed: busy ? null : () => submitRoom(true),
                  fontSize: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Future<void> submitRoom(bool join) async {
    final entered = codeInput.text.trim().toUpperCase();
    if (join && entered.length != 6) {
      info('Código inválido', 'Digite os seis caracteres do código da sala.');
      return;
    }
    if (!join && roomNameInput.text.trim().isEmpty) {
      info('Nome obrigatório', 'Dê um nome à sua sala.');
      return;
    }
    refresh(() => busy = true);
    try {
      final room = join
          ? await roomService.join(entered)
          : await roomService.create(
              roomNameInput.text.trim(),
              capacity,
              private,
            );
      if (!mounted) {
        return;
      }
      refresh(() {
        code = room['code'] as String;
        roomName = room['name'] as String;
        capacity = room['capacity'] as int;
        private = room['private'] as bool;
        ready = true;
        screen = 'lobby';
      });
    } catch (e) {
      if (mounted) {
        info(
          'Não foi possível abrir a sala',
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      refresh(() => busy = false);
    }
  }
}

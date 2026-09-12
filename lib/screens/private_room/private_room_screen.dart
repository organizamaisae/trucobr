part of '../../core/app.dart';

extension _PrivateScreen on _AuroraAppState {
  Widget playerSelector() => SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 2, label: Text('1v1')),
      ButtonSegment(value: 4, label: Text('2v2')),
    ],
    selected: {capacity},
    onSelectionChanged: (v) => refreshUI(() => capacity = v.first),
  );
  Widget rulesSelector() => DropdownButtonFormField<String>(
    isExpanded: true,
    initialValue: rule,
    decoration: const InputDecoration(labelText: 'Regra do Truco'),
    items: const [
      DropdownMenuItem(
        value: 'paulista',
        child: Text('Paulista • vira e manilha'),
      ),
      DropdownMenuItem(
        value: 'fixa',
        child: Text('Manilha fixa • pontuação paulista'),
      ),
    ],
    onChanged: (v) => refreshUI(() => rule = v!),
  );
  Widget privateScreen() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Criar sala')),
          ButtonSegment(value: 1, label: Text('Entrar com código')),
        ],
        selected: {privateTab},
        onSelectionChanged: (s) => refreshUI(() => privateTab = s.first),
      ),
      const SizedBox(height: 16),
      if (privateTab == 0) ...[
        heading('Criar sala'),
        TrucoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: roomInput,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nome da sala'),
              ),
              const SizedBox(height: 12),
              playerSelector(),
              const SizedBox(height: 16),
              rulesSelector(),
              const SizedBox(height: 16),
              TextField(
                controller: roomPassword,
                obscureText: true,
                maxLength: 64,
                decoration: const InputDecoration(
                  labelText: 'Senha da sala (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sala entre amigos • sem custo de entrada',
                style: TextStyle(color: gold, fontSize: 12),
              ),
              const SizedBox(height: 16),
              GameButton(
                'CRIAR SALA',
                icon: Icons.add,
                onPressed: busy
                    ? null
                    : () => enterRoom('create', {
                        'name': roomInput.text,
                        'capacity': capacity,
                        'rule': rule,
                        'password': roomPassword.text,
                        'fee': 0,
                      }),
              ),
            ],
          ),
        ),
      ] else ...[
        heading('Entrar com código'),
        TrucoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: codeInput,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de 6 caracteres',
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              TextField(
                controller: roomPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha da sala (opcional)',
                ),
              ),
              const SizedBox(height: 14),
              GameButton(
                'ENTRAR NA SALA',
                color: const Color(0xFF0064CB),
                onPressed: busy
                    ? null
                    : () => enterRoom('join', {
                        'code': codeInput.text.trim().toUpperCase(),
                        'password': roomPassword.text,
                      }),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

typedef OfficeAgentIdentity = ({String name, String look});

const _femaleNames = <String>[
  'Ana',
  'Beatriz',
  'Camila',
  'Daniela',
  'Eduarda',
  'Fernanda',
  'Gabriela',
  'Helena',
  'Isabela',
  'Júlia',
  'Larissa',
  'Mariana',
  'Natália',
  'Olívia',
  'Paula',
  'Rebeca',
  'Sofia',
  'Tatiana',
  'Valentina',
  'Yasmin',
  'Alice',
  'Bianca',
  'Cecília',
  'Débora',
  'Elisa',
  'Flávia',
  'Giovana',
  'Heloísa',
  'Iara',
  'Jéssica',
  'Lívia',
  'Manuela',
  'Melissa',
  'Nina',
  'Priscila',
  'Rafaela',
  'Sabrina',
  'Teresa',
  'Vitória',
  'Zoe',
  'Aline',
  'Bruna',
  'Clara',
  'Estela',
  'Fabiana',
  'Glória',
  'Ingrid',
  'Joana',
  'Kátia',
  'Lara',
  'Maitê',
  'Mirela',
  'Noemi',
  'Pietra',
  'Renata',
  'Simone',
  'Sara',
  'Vanessa',
  'Luana',
  'Marina',
];

const _maleNames = <String>[
  'Arthur',
  'Bruno',
  'Caio',
  'Diego',
  'Enzo',
  'Felipe',
  'Gustavo',
  'Henrique',
  'Igor',
  'João',
  'Kauã',
  'Lucas',
  'Mateus',
  'Nicolas',
  'Otávio',
  'Pedro',
  'Rafael',
  'Samuel',
  'Thiago',
  'Vinícius',
  'Bernardo',
  'Danilo',
  'Davi',
  'Emanuel',
  'Fábio',
  'Gael',
  'Heitor',
  'Hugo',
  'Joaquim',
  'Jorge',
  'Leonardo',
  'Lorenzo',
  'Luan',
  'Marcelo',
  'Murilo',
  'Noah',
  'Otto',
  'Raul',
  'Renato',
  'Ricardo',
  'Rodrigo',
  'Sérgio',
  'Theo',
  'Tomás',
  'Ulisses',
  'Vicente',
  'Wagner',
  'Yuri',
  'Augusto',
  'Benício',
  'César',
  'Douglas',
  'Elias',
  'Francisco',
  'Guilherme',
  'Ícaro',
  'Jonas',
  'Leandro',
  'Miguel',
  'Paulo',
];

final _pool = <OfficeAgentIdentity>[
  for (var i = 0; i < _femaleNames.length; i++) ...[
    (name: _femaleNames[i], look: 'f'),
    (name: _maleNames[i], look: 'm'),
  ],
];

/// Habblaud's deterministic FNV-1a selection over its Brazilian name pool.
OfficeAgentIdentity pickOfficeAgentIdentity(String id, Set<String> used) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  final start = hash % _pool.length;
  for (var offset = 0; offset < _pool.length; offset++) {
    final person = _pool[(start + offset) % _pool.length];
    if (!used.contains(person.name.toLowerCase())) return person;
  }
  final base = _pool[start];
  for (var suffix = 2; ; suffix++) {
    final name = '${base.name} $suffix';
    if (!used.contains(name.toLowerCase())) {
      return (name: name, look: base.look);
    }
  }
}

String officeAgentLookForName(String name, String fallback) {
  for (final person in _pool) {
    if (person.name.toLowerCase() == name.toLowerCase()) return person.look;
  }
  return fallback;
}

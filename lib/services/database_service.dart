import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/categoria.dart';
import '../models/fonte_renda.dart';
import '../models/despesa.dart';
import '../models/cartao_credito.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('expense_tracker.db');
      return _database!;
    } catch (e) {
      // Log do erro e relançar para que o chamador possa tratar
      print('Erro ao inicializar banco de dados: $e');
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        icone TEXT NOT NULL,
        limiteGasto REAL,
        isPadrao INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fontes_renda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        mes INTEGER NOT NULL,
        ano INTEGER NOT NULL,
        diaRecebimento INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        categoriaId INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        ano INTEGER NOT NULL,
        diaVencimento INTEGER,
        status INTEGER NOT NULL,
        isFixa INTEGER NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataCompra TEXT,
        cartaoCreditoId INTEGER,
        estabelecimento TEXT,
        isCompraOnline INTEGER NOT NULL DEFAULT 0,
        tipoPagamento INTEGER,
        numeroParcela INTEGER,
        totalParcelas INTEGER,
        parcelaId TEXT,
        FOREIGN KEY (categoriaId) REFERENCES categorias (id),
        FOREIGN KEY (cartaoCreditoId) REFERENCES cartoes_credito (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cartoes_credito (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        banco TEXT NOT NULL,
        numero TEXT NOT NULL,
        cor INTEGER NOT NULL,
        diaVencimento INTEGER,
        diaFechamento INTEGER,
        status INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE faturas_cartao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cartaoId INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        ano INTEGER NOT NULL,
        status INTEGER NOT NULL,
        FOREIGN KEY (cartaoId) REFERENCES cartoes_credito (id),
        UNIQUE(cartaoId, mes, ano)
      )
    ''');

    // Inserir categorias padrão
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categoriasPadrao = [
      Categoria(nome: 'Alimentação', icone: '🍔', isPadrao: true),
      Categoria(nome: 'Transporte', icone: '🚗', isPadrao: true),
      Categoria(
        nome: 'Combustível',
        icone: '⛽',
        limiteGasto: 500.0,
        isPadrao: true,
      ),
      Categoria(nome: 'Moradia', icone: '🏠', isPadrao: true),
      Categoria(nome: 'Saúde', icone: '⚕️', isPadrao: true),
      Categoria(nome: 'Educação', icone: '📚', isPadrao: true),
      Categoria(nome: 'Lazer', icone: '🎮', isPadrao: true),
      Categoria(
        nome: 'Diversos',
        icone: '📦',
        limiteGasto: 300.0,
        isPadrao: true,
      ),
      Categoria(nome: 'Pet', icone: '🐶', isPadrao: true),
      Categoria(nome: 'Impostos', icone: '💰', isPadrao: true),
      Categoria(nome: 'Internet/Telefone', icone: '📱', isPadrao: true),
      Categoria(nome: 'Seguros', icone: '🛡️', isPadrao: true),
      Categoria(nome: 'Farmácia', icone: '💊', isPadrao: true),
      Categoria(nome: 'Streams', icone: '🎬', isPadrao: true),
      Categoria(nome: 'Viagens', icone: '✈️', isPadrao: true),
      Categoria(nome: 'Academia', icone: '🏋️', isPadrao: true),
      Categoria(nome: 'Bares', icone: '🍺', isPadrao: true),
      Categoria(nome: 'Supermercado', icone: '🛒', isPadrao: true),
      Categoria(nome: 'Contas', icone: '📄', isPadrao: true),
      Categoria(nome: 'Vestuário', icone: '👕', isPadrao: true),
    ];

    for (var categoria in categoriasPadrao) {
      await db.insert('categorias', categoria.toMap());
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar coluna diaRecebimento na tabela fontes_renda
      await db.execute(
        'ALTER TABLE fontes_renda ADD COLUMN diaRecebimento INTEGER',
      );
    }
    if (oldVersion < 3) {
      // Criar tabela de cartões de crédito
      await db.execute('''
        CREATE TABLE cartoes_credito (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          banco TEXT NOT NULL,
          numero TEXT NOT NULL,
          cor INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Adicionar coluna cor na tabela cartoes_credito
      try {
        await db.execute('ALTER TABLE cartoes_credito ADD COLUMN cor INTEGER');
        // Atualizar registros existentes com cor padrão (azul - 0xFF2196F3 = 4294967283)
        await db.rawUpdate(
          'UPDATE cartoes_credito SET cor = ? WHERE cor IS NULL',
          [0xFF2196F3],
        );
        // Tornar a coluna NOT NULL após atualizar os valores
        // SQLite não suporta ALTER COLUMN, então precisamos recriar a tabela
        // Por enquanto, deixamos como nullable e tratamos no código
      } catch (e) {
        // Se a coluna já existir, ignora o erro
      }
    }
    if (oldVersion < 5) {
      // Adicionar colunas para despesas de cartão de crédito
      try {
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN cartaoCreditoId INTEGER',
        );
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN estabelecimento TEXT',
        );
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN isCompraOnline INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN tipoPagamento INTEGER',
        );
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN numeroParcela INTEGER',
        );
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN totalParcelas INTEGER',
        );
        await db.execute('ALTER TABLE despesas ADD COLUMN parcelaId TEXT');
      } catch (e) {
        // Se as colunas já existirem, ignora o erro
      }
    }
    if (oldVersion < 6) {
      // Adicionar coluna de vencimento na tabela cartoes_credito
      try {
        await db.execute(
          'ALTER TABLE cartoes_credito ADD COLUMN diaVencimento INTEGER',
        );
      } catch (e) {
        // Se a coluna já existir, ignora o erro
      }
    }
    if (oldVersion < 7) {
      // Adicionar coluna dataCompra na tabela despesas
      try {
        await db.execute('ALTER TABLE despesas ADD COLUMN dataCompra TEXT');
      } catch (e) {
        // Se a coluna já existir, ignora o erro
      }
    }
    if (oldVersion < 8) {
      // Adicionar coluna status na tabela cartoes_credito
      try {
        await db.execute(
          'ALTER TABLE cartoes_credito ADD COLUMN status INTEGER NOT NULL DEFAULT 3',
        );
      } catch (e) {
        // Se a coluna já existir, ignora o erro
      }
    }
    if (oldVersion < 9) {
      // Criar tabela de faturas de cartão para status por mês/ano
      try {
        await db.execute('''
          CREATE TABLE faturas_cartao (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cartaoId INTEGER NOT NULL,
            mes INTEGER NOT NULL,
            ano INTEGER NOT NULL,
            status INTEGER NOT NULL,
            FOREIGN KEY (cartaoId) REFERENCES cartoes_credito (id),
            UNIQUE(cartaoId, mes, ano)
          )
        ''');
      } catch (e) {
        // Se a tabela já existir, ignora o erro
      }
    }
    if (oldVersion < 11) {
      // Adicionar coluna isCompraOnline
      try {
        await db.execute(
          'ALTER TABLE despesas ADD COLUMN isCompraOnline INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        // Se a coluna já existir, ignora o erro
      }
    }
  }

  // CRUD Categorias
  Future<Categoria> createCategoria(Categoria categoria) async {
    final db = await instance.database;
    final id = await db.insert('categorias', categoria.toMap());
    return categoria.copyWith(id: id);
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await instance.database;
    final result = await db.query('categorias', orderBy: 'nome ASC');
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<List<Categoria>> buscarTodasCategorias() async {
    final db = await instance.database;
    final result = await db.query('categorias', orderBy: 'nome ASC');
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<Categoria?> getCategoria(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Categoria.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCategoria(Categoria categoria) async {
    final db = await instance.database;
    return db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await instance.database;

    // Deletar todas as despesas associadas a esta categoria
    await db.delete('despesas', where: 'categoriaId = ?', whereArgs: [id]);

    // Deletar a categoria (apenas se não for padrão)
    return db.delete(
      'categorias',
      where: 'id = ? AND isPadrao = 0',
      whereArgs: [id],
    );
  }

  // CRUD Fontes de Renda
  Future<FonteRenda> createFonteRenda(FonteRenda fonte) async {
    final db = await instance.database;
    final id = await db.insert('fontes_renda', fonte.toMap());
    return fonte.copyWith(id: id);
  }

  Future<List<FonteRenda>> getFontesRenda(int mes, int ano) async {
    final db = await instance.database;
    final result = await db.query(
      'fontes_renda',
      where: 'mes = ? AND ano = ?',
      whereArgs: [mes, ano],
    );
    return result.map((map) => FonteRenda.fromMap(map)).toList();
  }

  Future<List<String>> getNomesFontesRenda() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT nome FROM fontes_renda ORDER BY nome ASC',
    );
    return result.map((map) => map['nome'] as String).toList();
  }

  Future<List<FonteRenda>> buscarTodasFontesRenda() async {
    final db = await instance.database;
    final result = await db.query(
      'fontes_renda',
      orderBy: 'ano DESC, mes DESC',
    );
    return result.map((map) => FonteRenda.fromMap(map)).toList();
  }

  Future<int> updateFonteRenda(FonteRenda fonte) async {
    final db = await instance.database;
    return db.update(
      'fontes_renda',
      fonte.toMap(),
      where: 'id = ?',
      whereArgs: [fonte.id],
    );
  }

  Future<int> deleteFonteRenda(int id) async {
    final db = await instance.database;
    return db.delete('fontes_renda', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Despesas
  Future<Despesa> createDespesa(Despesa despesa) async {
    final db = await instance.database;
    final id = await db.insert('despesas', despesa.toMap());
    return despesa.copyWith(id: id);
  }

  Future<List<Despesa>> getDespesas(int mes, int ano) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'mes = ? AND ano = ?',
      whereArgs: [mes, ano],
      orderBy: 'diaVencimento ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasPorCategoriaId(int categoriaId) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'categoriaId = ?',
      whereArgs: [categoriaId],
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasFixas() async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'isFixa = 1',
      orderBy: 'diaVencimento ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> buscarTodasDespesas() async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      orderBy: 'ano DESC, mes DESC, diaVencimento ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<double> getTotalGastosPorCategoria(
    int categoriaId,
    int mes,
    int ano,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(valor) as total FROM despesas WHERE categoriaId = ? AND mes = ? AND ano = ?',
      [categoriaId, mes, ano],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<int> contarDespesasPorCategoria(int categoriaId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM despesas WHERE categoriaId = ?',
      [categoriaId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> updateDespesa(Despesa despesa) async {
    final db = await instance.database;
    return db.update(
      'despesas',
      despesa.toMap(),
      where: 'id = ?',
      whereArgs: [despesa.id],
    );
  }

  Future<int> deleteDespesa(int id) async {
    final db = await instance.database;
    return db.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Despesa>> getDespesasPorParcelaId(String parcelaId) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'parcelaId = ?',
      whereArgs: [parcelaId],
      orderBy: 'ano ASC, mes ASC, numeroParcela ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasNaoPagasPorParcelaId(
    String parcelaId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'parcelaId = ? AND status != ?',
      whereArgs: [parcelaId, StatusPagamento.pago.index],
      orderBy: 'ano ASC, mes ASC, numeroParcela ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasRecorrentesPorParcelaId(
    String parcelaId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'parcelaId = ? AND tipoPagamento = ?',
      whereArgs: [parcelaId, TipoPagamentoCartao.recorrente.index],
      orderBy: 'ano ASC, mes ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasRecorrentesNaoPagasPorParcelaId(
    String parcelaId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'parcelaId = ? AND tipoPagamento = ? AND status != ?',
      whereArgs: [
        parcelaId,
        TipoPagamentoCartao.recorrente.index,
        StatusPagamento.pago.index,
      ],
      orderBy: 'ano ASC, mes ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasParceladasFuturasNaoPagas(
    String parcelaId,
    int numeroParcelaAtual,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where:
          'parcelaId = ? AND tipoPagamento = ? AND status != ? AND numeroParcela >= ?',
      whereArgs: [
        parcelaId,
        TipoPagamentoCartao.parcelado.index,
        StatusPagamento.pago.index,
        numeroParcelaAtual,
      ],
      orderBy: 'ano ASC, mes ASC, numeroParcela ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<List<Despesa>> getDespesasRecorrentesFuturasNaoPagas(
    String parcelaId,
    int mesAtual,
    int anoAtual,
  ) async {
    final db = await instance.database;
    // Buscar despesas que são do mesmo mês/ano ou futuras
    final result = await db.query(
      'despesas',
      where:
          'parcelaId = ? AND tipoPagamento = ? AND status != ? AND (ano > ? OR (ano = ? AND mes >= ?))',
      whereArgs: [
        parcelaId,
        TipoPagamentoCartao.recorrente.index,
        StatusPagamento.pago.index,
        anoAtual,
        anoAtual,
        mesAtual,
      ],
      orderBy: 'ano ASC, mes ASC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<void> deleteDespesas(List<int> ids) async {
    final db = await instance.database;
    for (var id in ids) {
      await db.delete('despesas', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> copiarDespesasFixasParaMes(
    int mesOrigem,
    int anoOrigem,
    int mesDestino,
    int anoDestino,
  ) async {
    final despesasFixas = await getDespesasFixas();

    // Filtrar despesas do mês de origem
    final despesasMesOrigem = despesasFixas
        .where((d) => d.mes == mesOrigem && d.ano == anoOrigem)
        .toList();

    for (var despesa in despesasMesOrigem) {
      final novaDespesa = despesa.copyWith(
        mes: mesDestino,
        ano: anoDestino,
        status: StatusPagamento.aPagar,
        dataCriacao: DateTime.now(),
        clearId: true,
      );
      await createDespesa(novaDespesa);
    }
  }

  // CRUD Cartões de Crédito
  Future<CartaoCredito> createCartaoCredito(CartaoCredito cartao) async {
    final db = await instance.database;
    final id = await db.insert('cartoes_credito', cartao.toMap());
    return cartao.copyWith(id: id);
  }

  Future<List<CartaoCredito>> getCartoesCredito() async {
    final db = await instance.database;
    final result = await db.query('cartoes_credito', orderBy: 'nome ASC');
    return result.map((map) => CartaoCredito.fromMap(map)).toList();
  }

  Future<CartaoCredito?> getCartaoCredito(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'cartoes_credito',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return CartaoCredito.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCartaoCredito(CartaoCredito cartao) async {
    final db = await instance.database;
    return db.update(
      'cartoes_credito',
      cartao.toMap(),
      where: 'id = ?',
      whereArgs: [cartao.id],
    );
  }

  Future<int> contarDespesasPorCartao(int cartaoId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM despesas WHERE cartaoCreditoId = ?',
      [cartaoId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteCartaoCredito(int id) async {
    final db = await instance.database;
    // Deletar todas as despesas associadas ao cartão
    await db.delete('despesas', where: 'cartaoCreditoId = ?', whereArgs: [id]);
    // Deletar faturas associadas
    await db.delete('faturas_cartao', where: 'cartaoId = ?', whereArgs: [id]);
    return db.delete('cartoes_credito', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Faturas de Cartão (status por mês/ano)
  Future<void> atualizarStatusFatura(
    int cartaoId,
    int mes,
    int ano,
    StatusPagamento status,
  ) async {
    final db = await instance.database;
    // Verificar se já existe uma fatura para este cartão/mês/ano
    final existing = await db.query(
      'faturas_cartao',
      where: 'cartaoId = ? AND mes = ? AND ano = ?',
      whereArgs: [cartaoId, mes, ano],
    );

    if (existing.isNotEmpty) {
      // Atualizar existente
      await db.update(
        'faturas_cartao',
        {'status': status.index},
        where: 'cartaoId = ? AND mes = ? AND ano = ?',
        whereArgs: [cartaoId, mes, ano],
      );
    } else {
      // Criar nova
      await db.insert('faturas_cartao', {
        'cartaoId': cartaoId,
        'mes': mes,
        'ano': ano,
        'status': status.index,
      });
    }
  }

  Future<StatusPagamento?> getStatusFatura(
    int cartaoId,
    int mes,
    int ano,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'faturas_cartao',
      where: 'cartaoId = ? AND mes = ? AND ano = ?',
      whereArgs: [cartaoId, mes, ano],
    );

    if (result.isNotEmpty) {
      return StatusPagamento.values[result.first['status'] as int];
    }
    return null; // Retorna null se não houver status específico (usa padrão do cartão)
  }

  Future<List<Map<String, dynamic>>> buscarTodasFaturasCartao() async {
    final db = await instance.database;
    return await db.query('faturas_cartao', orderBy: 'ano DESC, mes DESC');
  }

  Future<List<CartaoCredito>> buscarTodosCartoesCredito() async {
    final db = await instance.database;
    final result = await db.query('cartoes_credito', orderBy: 'nome ASC');
    return result.map((map) => CartaoCredito.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

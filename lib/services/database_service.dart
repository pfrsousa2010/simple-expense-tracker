import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/categoria.dart';
import '../models/fonte_renda.dart';
import '../models/despesa.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        ano INTEGER NOT NULL
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
        FOREIGN KEY (categoriaId) REFERENCES categorias (id)
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
      Categoria(nome: 'Contas', icone: '📄', isPadrao: true),
      Categoria(nome: 'Vestuário', icone: '👕', isPadrao: true),
    ];

    for (var categoria in categoriasPadrao) {
      await db.insert('categorias', categoria.toMap());
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

  Future<List<Despesa>> getDespesasFixas() async {
    final db = await instance.database;
    final result = await db.query(
      'despesas',
      where: 'isFixa = 1',
      orderBy: 'diaVencimento ASC',
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

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

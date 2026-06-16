import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/banco_broker.dart';
import '../models/oferta_hipotecaria.dart';
import '../models/tramo_interes.dart';
import '../models/vinculacion.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hipotecas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
        ),
      );
    } else {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, filePath);

      return await openDatabase(
        path,
        version: 1,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bancos_brokers (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        tipoEntidad TEXT NOT NULL,
        contactoGestor TEXT,
        notas TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ofertas_hipotecarias (
        id TEXT PRIMARY KEY,
        bancoBrokerId TEXT NOT NULL,
        nombreOferta TEXT NOT NULL,
        fechaOferta TEXT NOT NULL,
        capitalSolicitado REAL NOT NULL,
        plazoAnios INTEGER NOT NULL,
        comisionAperturaPorcentaje REAL NOT NULL,
        gastosTasacion REAL NOT NULL,
        FOREIGN KEY (bancoBrokerId) REFERENCES bancos_brokers (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE tramos_interes (
        id TEXT PRIMARY KEY,
        ofertaId TEXT NOT NULL,
        anioInicio INTEGER NOT NULL,
        anioFin INTEGER NOT NULL,
        tinBase REAL NOT NULL,
        esVariable INTEGER NOT NULL,
        diferencialEuribor REAL NOT NULL,
        FOREIGN KEY (ofertaId) REFERENCES ofertas_hipotecarias (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vinculaciones (
        id TEXT PRIMARY KEY,
        ofertaId TEXT NOT NULL,
        tipoVinculacion TEXT NOT NULL,
        descuentoTin REAL NOT NULL,
        costeAnual REAL NOT NULL,
        esObligatorio INTEGER NOT NULL,
        FOREIGN KEY (ofertaId) REFERENCES ofertas_hipotecarias (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE amortizaciones_anticipadas (
        id TEXT PRIMARY KEY,
        ofertaId TEXT NOT NULL,
        mesNumero INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        tipoAmortizacion TEXT NOT NULL,
        FOREIGN KEY (ofertaId) REFERENCES ofertas_hipotecarias (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- REPOSITORIOS BÁSICOS ---

  // BancoBroker
  Future<void> insertBancoBroker(BancoBroker bancoBroker) async {
    final db = await instance.database;
    await db.insert('bancos_brokers', bancoBroker.toMap());
  }

  Future<List<BancoBroker>> getBancosBrokers() async {
    final db = await instance.database;
    final result = await db.query('bancos_brokers');
    return result.map((json) => BancoBroker.fromMap(json)).toList();
  }

  // OfertaHipotecaria Completa (Transacción)
  Future<void> insertOfertaCompleta({
    required OfertaHipotecaria oferta,
    List<TramoInteres>? tramos,
    List<Vinculacion>? vinculaciones,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.insert('ofertas_hipotecarias', oferta.toMap());

      if (tramos != null) {
        for (final tramo in tramos) {
          await txn.insert('tramos_interes', tramo.toMap());
        }
      }

      if (vinculaciones != null) {
        for (final vinculacion in vinculaciones) {
          await txn.insert('vinculaciones', vinculacion.toMap());
        }
      }
    });
  }

  Future<List<OfertaHipotecaria>> getOfertasHipotecarias() async {
    final db = await instance.database;
    final result = await db.query('ofertas_hipotecarias');
    return result.map((json) => OfertaHipotecaria.fromMap(json)).toList();
  }

  Future<List<TramoInteres>> getTramosPorOferta(String ofertaId) async {
    final db = await instance.database;
    final result = await db.query(
      'tramos_interes',
      where: 'ofertaId = ?',
      whereArgs: [ofertaId],
    );
    return result.map((json) => TramoInteres.fromMap(json)).toList();
  }

  Future<OfertaHipotecaria?> getOfertaById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'ofertas_hipotecarias',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return OfertaHipotecaria.fromMap(result.first);
    }
    return null;
  }

  Future<List<Vinculacion>> getVinculacionesPorOferta(String ofertaId) async {
    final db = await instance.database;
    final result = await db.query(
      'vinculaciones',
      where: 'ofertaId = ?',
      whereArgs: [ofertaId],
    );
    return result.map((json) => Vinculacion.fromMap(json)).toList();
  }

  Future<List<AmortizacionAnticipada>> getAmortizacionesPorOferta(String ofertaId) async {
    final db = await instance.database;
    final result = await db.query(
      'amortizaciones_anticipadas',
      where: 'ofertaId = ?',
      whereArgs: [ofertaId],
    );
    return result.map((json) => AmortizacionAnticipada.fromMap(json)).toList();
  }
}

// package.dart

// Modelo para paquete
class PackageRecord {
  final String paqId;
  final String nombRec;
  final String destino;
  final String estatus;

  PackageRecord({
    required this.paqId, 
    required this.nombRec, 
    required this.destino,
    required this.estatus,
  });

  factory PackageRecord.fromJson(Map<String, dynamic> json) {
    return PackageRecord(
      paqId: json['paq_id'] as String,
      nombRec: json['nomb_rec'] as String,
      destino: json['destino'] as String,
      estatus: json['estatus'] as String,
    );
  }
}
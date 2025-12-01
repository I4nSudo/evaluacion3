// agent.dart

// Modelo de datos del agente (respuesta del login)
class AgentData {
  final int empId;
  final String nombre;
  final String rol;

  AgentData({required this.empId, required this.nombre, required this.rol});

  factory AgentData.fromJson(Map<String, dynamic> json) {
    return AgentData(
      empId: json['emp_id'] as int,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
    );
  }
}

// Modelo para Agentes Simples (para el Dropdown en AdminPanelPage)
class SimpleAgent {
  final int empId;
  final String nombre;
  SimpleAgent({required this.empId, required this.nombre});

  factory SimpleAgent.fromJson(Map<String, dynamic> json) {
    return SimpleAgent(
      empId: json['emp_id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  @override
  bool operator ==(Object other) => 
      identical(this, other) || 
      (other is SimpleAgent && other.empId == empId);

  @override
  int get hashCode => empId.hashCode;
}
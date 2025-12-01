// admin_panel_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';
import 'agent.dart';
import 'login_page.dart';

// ----------------------------------------------------
// PANTALLA DEL PANEL DE ADMINISTRACIÓN
// ----------------------------------------------------

class AdminPanelPage extends StatefulWidget {
  final AgentData agent;
  const AdminPanelPage({super.key, required this.agent});

  @override
  AdminPanelPageState createState() => AdminPanelPageState();
}

class AdminPanelPageState extends State<AdminPanelPage> {
  final TextEditingController _paqIdController = TextEditingController();
  final TextEditingController _nombRecController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  
  List<SimpleAgent> _agents = [];
  SimpleAgent? _selectedAgent;
  String _message = "";
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _fetchAgents(); // Cargar la lista de agentes al inicio
  }

  // >>> Implementación: Obtener la lista de agentes <<<
  Future<void> _fetchAgents() async {
    try {
      // Endpoint GET: /api/v1/admin/agents-list (Se requiere autenticación y rol ADMIN)
      var url = Uri.parse("$baseUrl/api/v1/admin/agents-list");
      
      // En un entorno real, enviarías el token de autenticación del ADMIN aquí
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _agents = jsonList.map((json) => SimpleAgent.fromJson(json)).toList();
          _selectedAgent = _agents.isNotEmpty ? _agents.first : null;
        });
      } else {
        setState(() {
          _message = "❌ Error al cargar agentes: Código ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error de conexión al cargar agentes: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // >>> Implementación: Asignar Paquete (POST) <<<
  Future<void> _assignPackage() async {
    if (_paqIdController.text.isEmpty || _nombRecController.text.isEmpty || _destinoController.text.isEmpty || _selectedAgent == null) {
      setState(() => _message = "❌ Todos los campos son obligatorios.");
      return;
    }

    setState(() {
      _isAssigning = true;
      _message = "Asignando paquete...";
    });

    try {
      // Endpoint POST: /api/v1/admin/create-and-assign-package
      var url = Uri.parse("$baseUrl/api/v1/admin/create-and-assign-package");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "paq_id": _paqIdController.text,
          "nomb_rec": _nombRecController.text,
          "destino": _destinoController.text,
          "assigned_emp_id": _selectedAgent!.empId,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        setState(() {
          _message = "✅ Paquete ${_paqIdController.text} asignado a ${_selectedAgent!.nombre} con éxito.";
        });
        // Limpiar formulario
        _paqIdController.clear();
        _nombRecController.clear();
        _destinoController.clear();
      } else {
        setState(() {
          _message = data['detail'] ?? "❌ Error desconocido al asignar paquete.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error de conexión al asignar paquete: $e";
      });
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel Admin: ${widget.agent.nombre}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "Asignación de Paquetes",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 30),

            // Campo ID de Paquete
            TextField(
              controller: _paqIdController,
              decoration: const InputDecoration(
                labelText: 'ID del Paquete (paq_id)',
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 15),

            // Campo Nombre del Receptor
            TextField(
              controller: _nombRecController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Receptor',
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 15),

            // Campo Destino
            TextField(
              controller: _destinoController,
              decoration: const InputDecoration(
                labelText: 'Destino/Dirección',
                prefixIcon: Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),

            // Selector de Agente
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_agents.isEmpty)
              const Text("No hay agentes disponibles para asignar.", style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<SimpleAgent>(
                decoration: const InputDecoration(
                  labelText: 'Agente de Entrega Asignado',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                initialValue: _selectedAgent,
                items: _agents.map<DropdownMenuItem<SimpleAgent>>((agent) {
                  return DropdownMenuItem<SimpleAgent>(
                    value: agent,
                    child: Text('${agent.nombre} (ID: ${agent.empId})'),
                  );
                }).toList(),
                onChanged: (SimpleAgent? newValue) {
                  setState(() {
                    _selectedAgent = newValue;
                  });
                },
              ),
            
            const SizedBox(height: 30),

            // Botón de Asignación
            ElevatedButton(
              onPressed: _isAssigning ? null : _assignPackage,
              child: _isAssigning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('CREAR Y ASIGNAR PAQUETE'),
            ),
            const SizedBox(height: 20),

            // Mensaje de Resultado
            if (_message.isNotEmpty)
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message.startsWith('❌') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// package_list_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '/main.dart';
import '/agent.dart';
import '/package.dart';
import '/login_page.dart';
import '/package_card.dart';


// ----------------------------------------------------
// PANTALLA DE PAQUETES ASIGNADOS
// ----------------------------------------------------

class PackageListPage extends StatefulWidget {
  final AgentData agent;

  const PackageListPage({super.key, required this.agent});

  @override
  // ignore: library_private_types_in_public_api
  _PackageListPageState createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  List<PackageRecord> packages = [];
  bool _isLoading = false;
  String _message = "Cargando paquetes...";

  @override
  void initState() {
    super.initState();
    _fetchAssignedPackages();
  }

  Future<void> _fetchAssignedPackages() async {
    setState(() {
      _isLoading = true;
      packages = [];
      _message = "Cargando paquetes...";
    });

    try {
      // Endpoint GET: /api/v1/packages/assigned/{emp_id}
      var url = Uri.parse("$baseUrl/api/v1/packages/assigned/${widget.agent.empId}");
      
      // En un entorno real, aquí se enviarían los JWT en el header de autorización.
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        
        setState(() {
          packages = jsonList.map((json) => PackageRecord.fromJson(json)).toList();
          _message = packages.isEmpty
              ? "No tienes paquetes ASIGNADOS pendientes de entrega."
              : "Paquetes asignados cargados correctamente.";
        });
      } else {
        setState(() {
          _message = "❌ Error al cargar paquetes: Código ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error de conexión al cargar paquetes: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ruta de ${widget.agent.nombre}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAssignedPackages,
            tooltip: 'Recargar Paquetes',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navegar de vuelta a la página de login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (packages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return PackageCard(
                      package: package,
                      agentId: widget.agent.empId,
                      onDeliveryRegistered: _fetchAssignedPackages, // Recargar al completar entrega
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
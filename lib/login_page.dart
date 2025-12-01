// login_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '/main.dart';
import '/agent.dart';
import '/admin_panel_page.dart';
import '/package_list_page.dart';
import '/register_page.dart';

// ----------------------------------------------------
// PANTALLA DE LOGIN
// ----------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";
  bool _isLoading = false;

  Future<void> _attemptLogin() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      final empId = int.tryParse(_idController.text);
      if (empId == null) {
        setState(() {
          _message = "❌ El ID del Empleado debe ser un número.";
          _isLoading = false;
        });
        return;
      }

      var url = Uri.parse("$baseUrl/api/v1/auth/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "emp_id": empId,
          "password": _passwordController.text,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Login Exitoso
        final agentData = AgentData.fromJson(data);
        
        // >>> LÓGICA DE REDIRECCIÓN BASADA EN ROL <<<
        Widget nextScreen;
        if (agentData.rol == 'ADMINISTRADOR') {
          // Si es ADMIN, vamos al nuevo Panel de Administración
          nextScreen = AdminPanelPage(agent: agentData);
        } else {
          // Si es AGENTE, vamos a la lista de paquetes asignados
          nextScreen = PackageListPage(agent: agentData);
        }

        // Navegar a la página correspondiente
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => nextScreen,
          ),
        );
      } else {
        // Fallo de Login (ej. 401 Credenciales inválidas)
        setState(() {
          _message = data['detail'] ?? "❌ Error desconocido al iniciar sesión.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error de conexión: Verifica que tu API esté activa.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paquexpress Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                "Acceso Agentes de Entrega",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 40),

              // Campo de ID de Empleado
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID de Empleado (emp_id)',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Botón de Login
              ElevatedButton(
                onPressed: _isLoading ? null : _attemptLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('INGRESAR'),
              ),
              const SizedBox(height: 20),

              // Mensaje de Error
              if (_message.isNotEmpty)
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                
              const SizedBox(height: 10),

              // Botón de Navegación a Registro
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text('¿Necesitas registrar un nuevo agente?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
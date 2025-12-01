// register_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'main.dart';

// ----------------------------------------------------
// PANTALLA DE REGISTRO DE AGENTE
// ----------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";
  bool _isLoading = false;
  String _selectedRol = 'AGENTE';

  Future<void> _attemptRegister() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      // Usamos el endpoint de registro de administrador
      var url = Uri.parse("$baseUrl/api/v1/admin/register-agent");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "nombre": _nombreController.text,
          "password": _passwordController.text,
          "rol": _selectedRol,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Registro Exitoso
        setState(() {
          _message = "✅ Agente registrado con éxito. Su ID es: ${data['emp_id']}. Ahora inicie sesión.";
        });
        
        // Navegar de vuelta al Login después de un pequeño retraso.
        Future.delayed(const Duration(seconds: 3), () {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(); 
        });

      } else {
        // Fallo de Registro 
        setState(() {
          _message = data['detail'] ?? "❌ Error desconocido al registrar.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error de conexión: $e";
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
      appBar: AppBar(title: const Text("Registro de Nuevo Agente")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                "Registro de Agente",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 40),

              // Campo Nombre Completo
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo del Agente',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (Para Login)',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Selector de Rol
              const Text(
                'Seleccionar Rol:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_pin),
                  labelText: 'Rol del Agente',
                  filled: true,
                ),
                initialValue: _selectedRol,
                items: const [
                  DropdownMenuItem(value: 'AGENTE', child: Text('AGENTE')),
                  DropdownMenuItem(value: 'ADMINISTRADOR', child: Text('ADMINISTRADOR')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRol = newValue;
                    });
                  }
                }
              ),

              const SizedBox(height: 30), 
              // Botón de Registro
              ElevatedButton(
                onPressed: _isLoading ? null : _attemptRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('REGISTRAR'),
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
      ),
    );
  }
}
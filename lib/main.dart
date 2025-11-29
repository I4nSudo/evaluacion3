import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; 
import 'package:http_parser/http_parser.dart'; 

const String baseUrl = "http://localhost:8000";

void main() => runApp(const MyApp());

// ----------------------------------------------------
// 1. MODELOS DE DATOS Y UTILIDADES
// ----------------------------------------------------

// Modelo para el historial de asistencias
class AgentData{
  final int empId;
  final String nombre;

  AgentData({required this.empId, required this.nombre});

  factory AgentData.fromJson(Map<String, dynamic> json) {
    return AgentData(
      empId: json['emp_id'] as int,
      nombre: json['nombre'] as String,);
  }
}
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

// ----------------------------------------------------
// 2. WIDGET PRINCIPAL Y TEMAS
// ----------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de colores y estilos para toda la app
    final primaryColor = const Color(0xFF0D47A1); // Azul oscuro
    final secondaryColor = const Color(0xFF1565C0); // Azul medio

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paquexpress',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFF607D8B), // Azul claro
        appBarTheme: AppBarTheme(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: secondaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // La página de inicio es el Login
      home: const LoginPage(),
    );
  }
}

// ----------------------------------------------------
// 3. PANTALLA DE LOGIN
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
        // Navegar a la página de paquetes asignados
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PackageListPage(agent: agentData),
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

// ----------------------------------------------------
// 4. PANTALLA DE REGISTRO DE AGENTE
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

// ----------------------------------------------------
// 5. PANTALLA DE PAQUETES ASIGNADOS (PackageListPage)
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

// ----------------------------------------------------
// 6. CARD INDIVIDUAL DEL PAQUETE
// ----------------------------------------------------

class PackageCard extends StatelessWidget {
  final PackageRecord package;
  final int agentId;
  final Function onDeliveryRegistered;

  const PackageCard({
    super.key,
    required this.package,
    required this.agentId,
    required this.onDeliveryRegistered,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el color y el ícono basado en el estatus
    IconData icon;
    Color color;
    switch (package.estatus) {
      case 'ENTREGADO':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'EN_TRANSITO':
        icon = Icons.local_shipping;
        color = Colors.orange;
        break;
      case 'FALLIDO':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'ASIGNADO':
      default:
        icon = Icons.assignment_ind;
        color = Colors.blue;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(
          package.paqId,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinatario: ${package.nombRec}'),
            Text('Dirección: ${package.destino}'),
            Text('Estatus: ${package.estatus}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: package.estatus != 'ENTREGADO' 
          ? IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.lightGreen),
              onPressed: () {
                // Navegar a la página de registro de entrega
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DeliveryRegisterPage(
                      package: package,
                      agentId: agentId,
                      onDeliveryRegistered: onDeliveryRegistered,
                    ),
                  ),
                );
              },
              tooltip: 'Registrar Entrega',
            )
          : const Icon(Icons.check, color: Colors.green),
      ),
    );
  }
}

// ----------------------------------------------------
// 7. PANTALLA DE REGISTRO DE ENTREGA (DeliveryRegisterPage)
// ----------------------------------------------------

class DeliveryRegisterPage extends StatefulWidget {
  final PackageRecord package;
  final int agentId;
  final Function onDeliveryRegistered;

  const DeliveryRegisterPage({
    super.key,
    required this.package,
    required this.agentId,
    required this.onDeliveryRegistered,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DeliveryRegisterPageState createState() => _DeliveryRegisterPageState();
}

class _DeliveryRegisterPageState extends State<DeliveryRegisterPage> {
  XFile? _imageFile;
  String _estatusEntrega = 'EXITOSA'; // Default
  String _message = "Debe tomar una foto para continuar.";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    setState(() {
      _imageFile = image;
      if (_imageFile != null) {
        _message = "Foto capturada. Seleccione el estatus y complete el registro.";
      }
    });
  }

  Future<void> _registerDelivery() async {
    if (_imageFile == null) {
      setState(() => _message = "❌ Por favor, toma la foto de evidencia antes de enviar.");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "Registrando entrega...";
    });

    try {
      // 1. Obtener la posición GPS
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Preparar la solicitud Multipart
      var uri = Uri.parse("$baseUrl/api/v1/delivery/register");
      var request = http.MultipartRequest('POST', uri)
        ..fields['paq_id'] = widget.package.paqId
        ..fields['latitude'] = pos.latitude.toString()
        ..fields['longitude'] = pos.longitude.toString()
        ..fields['emp_id'] = widget.agentId.toString()
        ..fields['estatus_entrega'] = _estatusEntrega;

      // Adjuntar la foto como MultipartFile
      request.files.add(await http.MultipartFile.fromPath(
        'photo_file', 
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'), // Asume JPEG
      ));

      // 3. Enviar la solicitud
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final decoded = utf8.decode(response.bodyBytes);
      final data = json.decode(decoded);

      // 4. Procesar respuesta
      if (response.statusCode == 200) {
        setState(() {
          _message = "✅ Entrega registrada. Estatus: $_estatusEntrega.\nFoto URL (Simulación): ${data['foto_url']}";
        });

        // Recargar la lista de paquetes en la pantalla anterior y cerrar esta
        await widget.onDeliveryRegistered();
        // ignore: use_build_context_synchronously
        Future.delayed(const Duration(seconds: 2), () {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(); 
        });
        
      } else {
        setState(() {
          _message = "❌ Error ${response.statusCode}: ${data['detail'] ?? 'Error desconocido'}";
        });
      }
      
    } catch (e) {
      setState(() {
        _message = "❌ Error al registrar entrega: $e";
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
      appBar: AppBar(title: Text("Registrar Entrega: ${widget.package.paqId}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen del Paquete
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Destinatario: ${widget.package.nombRec}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Dirección: ${widget.package.destino}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selector de Estatus
            const Text("Resultado de la Entrega:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Exitosa'),
                    value: 'EXITOSA',
                    groupValue: _estatusEntrega,
                    onChanged: (value) {
                      setState(() {
                        _estatusEntrega = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Fallida'),
                    value: 'FALLIDA',
                    groupValue: _estatusEntrega,
                    onChanged: (value) {
                      setState(() {
                        _estatusEntrega = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Previsualización de la Foto
            Center(
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: _imageFile != null
                    ? Image.file(
                        File(_imageFile!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Text("Error al cargar imagen")),
                      )
                    : const Center(
                        child: Text("Vista previa de la foto de evidencia"),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Botón Tomar Foto
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_imageFile == null ? 'TOMAR FOTO DE EVIDENCIA' : 'RE-TOMAR FOTO'),
              onPressed: _isLoading ? null : _takePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Botón Finalizar Registro
            ElevatedButton.icon(
              icon: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Icon(Icons.send),
              label: Text(_isLoading ? 'ENVIANDO...' : 'FINALIZAR REGISTRO'),
              onPressed: _isLoading || _imageFile == null ? null : _registerDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje de estado
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _message.startsWith('❌') ? Colors.red : Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// delivery_register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '/main.dart';
import '/package.dart';

// ----------------------------------------------------
// PANTALLA DE REGISTRO DE ENTREGA
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

      // Adjuntar la foto como MultipartFile (Manejo de plataforma)
      if (kIsWeb) {
        // En la web, el archivo se carga como bytes
        request.files.add(http.MultipartFile.fromBytes(
          'photo_file',
          await _imageFile!.readAsBytes(),
          filename: _imageFile!.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        // En plataformas nativas, se carga desde la ruta del archivo
        request.files.add(await http.MultipartFile.fromPath(
          'photo_file',
          _imageFile!.path,
          contentType: MediaType('image', 'jpeg'), // Asume JPEG
        ));
      }

      // 3. Enviar la solicitud
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final decoded = utf8.decode(response.bodyBytes);
      final data = json.decode(decoded);

      // 4. Procesar respuesta
      if (response.statusCode == 200) {
        setState(() {
          _message = " Entrega registrada. Estatus: $_estatusEntrega.\nFoto URL (Simulación): ${data['foto_url']}";
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

            // Selector de Estatus (Nota: Contiene código deprecated que causa warnings)
            const Text("Resultado de la Entrega:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            
RadioGroup<String>(
              // 1. El estado se controla aquí arriba (PADRE)
              groupValue: _estatusEntrega, 
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _estatusEntrega = value;
                  });
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Exitosa'),
                      value: 'EXITOSA',
                      // 2. ¡OJO! Aquí ya borramos 'groupValue' y 'onChanged'
                      // porque ahora los maneja el padre.
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Fallida'),
                      value: 'FALLIDA',
                      // Aquí igual, código limpio.
                    ),
                  ),
                ],
              ),
            ), // Fin del Row
            // ---------------------------------------------
            
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
                    ? kIsWeb
                    ? FutureBuilder<Uint8List>(
                      future: _imageFile!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      )
                      : Image.file(
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

            // Botón de tomar foto
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('TOMAR FOTO DE EVIDENCIA'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje de estado
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _message.startsWith('❌') ? Colors.red : Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Botón de Registro de Entrega
            ElevatedButton(
              onPressed: _isLoading || _imageFile == null ? null : _registerDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('COMPLETAR REGISTRO DE ENTREGA', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
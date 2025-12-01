// package_card.dart

import 'package:flutter/material.dart';
import 'package.dart';
import 'delivery_register_page.dart';

// ----------------------------------------------------
// CARD INDIVIDUAL DEL PAQUETE
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
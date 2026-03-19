import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';
import 'package:cuot_app/ui/pages/seguimiento_creditos_page.dart';
import 'package:cuot_app/ui/pages/settings_screen.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String nombre_usuario;
  final String ventanaActiva; // 👈 Recibe la ventana activa

  const CustomDrawer({
    super.key,
    required this.nombre_usuario,
    required this.ventanaActiva, // 👈 Requerido
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.pureWhite,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del Drawer con gradiente verde
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    16, // Espacio para el status bar
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.lightGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Que crezca según su contenido
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.pureWhite,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre_usuario.isNotEmpty
                        ? 'Hola, ${nombre_usuario.split(' ').first}'
                        : 'Hola, Usuario',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ver perfil',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Items del menú con detección de ventana activa
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Menu Principal',
              onTap: () {
                Navigator.pop(context); // Cerrar el drawer primero
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                            correo: '',
                            userName: nombre_usuario,
                          )),
                );
              },
              isSelected: ventanaActiva == 'dashboard', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.credit_card,
              label: 'Cuotas Personales',
              onTap: () {
                Navigator.pop(context); // Cerrar el drawer primero
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SeguimientoCreditosPage(
                            nombreUsuario: nombre_usuario,
                          )),
                );
              },
              isSelected: ventanaActiva == 'Cuotas Personales', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.payment,
              label: 'Cuotas Comunitarias',
              onTap: () {
                // TODO: Implementar navegación a pagos
              },
              isSelected:
                  ventanaActiva == 'Cuotas Comunitarias', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.calendar_today,
              label: 'Cuotas Empresariales',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a calendario
              },
              isSelected:
                  ventanaActiva == 'Cuotas Empresariales', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.history,
              label: 'Historial',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a historial
              },
              isSelected: ventanaActiva == 'historial', // 👈 Condición
            ),

            const Divider(
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildDrawerItem(
              icon: Icons.notifications_outlined,
              label: 'Notificaciones',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a notificaciones
              },
              showBadge: true,
              badgeCount: 3,
              isSelected: ventanaActiva == 'notificaciones', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.settings,
              label: 'Configuración',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      nombreUsuario: nombre_usuario,
                    ),
                  ),
                );
              },
              isSelected: ventanaActiva == 'Configuración', // 👈 Condición
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              label: 'Ayuda',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a ayuda
              },
              isSelected: ventanaActiva == 'ayuda', // 👈 Condición
            ),

            const Divider(
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildDrawerItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => CuotAppLoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              color: AppColors.error,
              isSelected: false, // Nunca está seleccionado
            ),

            const SizedBox(height: 20),

            // Versión de la app
            Center(
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  color: AppColors.mediumGrey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir items del drawer
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isSelected = false,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ??
            (isSelected ? AppColors.primaryGreen : AppColors.mediumGrey),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ??
              (isSelected ? AppColors.primaryGreen : AppColors.darkGrey),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: showBadge
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

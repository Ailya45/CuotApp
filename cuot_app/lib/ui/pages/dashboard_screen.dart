// lib/ui/pages/dashboard_screen.dart
import 'package:cuot_app/Controller/dashboard_controller.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/widget/dashboard/credit_summary_cards.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:cuot_app/widget/dashboard/overdue_payments.dart';
import 'package:cuot_app/widget/dashboard/upcoming_payments.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuot_app/ui/pages/seguimiento_creditos_page.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';

class DashboardScreen extends StatelessWidget {
  final String? userName;
  final String? correo;

  // Llave global del Scaffold para controlar el Drawer manualmente
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DashboardScreen({super.key, required this.correo, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardController(correo: correo, userName: userName),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          final scaffoldState = _scaffoldKey.currentState;
          if (scaffoldState?.isDrawerOpen ?? false) {
            scaffoldState?.closeDrawer();
            return;
          }

          // Mostrar diálogo de confirmación
          final bool? shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Cerrar sesión?'),
              content: const Text('¿Estás seguro de que deseas cerrar la sesión y salir al login?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('CERRAR SESIÓN'),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CuotAppLoginPage()),
              (Route<dynamic> route) => false,
            );
          }
        },
        child: Consumer<DashboardController>(
          builder: (context, controller, child) {
            return Scaffold(
              key: _scaffoldKey,
              drawer: CustomDrawer(
                nombre_usuario: userName ?? "Usuario no encontrado", 
                ventanaActiva: "dashboard"
              ),
              body: RefreshIndicator(
                onRefresh: () => controller.refreshData(),
                color: AppColors.primaryGreen,
                child: CustomScrollView(
                  slivers: [
                    // App Bar personalizada - VERSIÓN CORREGIDA SIN SUPERPOSICIÓN
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: true,
                      pinned: true,
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      leading: Builder(
                        builder: (context) => Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: EdgeInsets.zero,
                        title: Container(
                          height: 60,
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.only(left: 20, bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8)
                                
                  
                                
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hola,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    controller.getFirstName(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Fondo con gradiente
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryGreen,
                                    AppColors.lightGreen,
                                  ],
                                ),
                              ),
                            ),
                            // Contenido del fondo
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  top: 60,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Panel de Control',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Resumen Financiero',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: const [], // Vacío para eliminar los iconos
                    ),

                    // Contenido principal
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (controller.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (controller.errorMessage != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      controller.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => controller.refreshData(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            // 1-4. Tarjetas de resumen
                            CreditSummaryCards(
                              totalCredits: controller.totalCredits,
                              totalPaid: controller.totalPaid,
                              pendingWeeklyQuotas: controller.pendingWeeklyQuotas,
                              pendingBalance: controller.pendingBalance,
                              onTapActiveCredits: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeguimientoCreditosPage(
                                      nombreUsuario: userName ?? "Usuario",
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // 5. Próximos vencimientos
                            UpcomingPayments(
                              payments: controller.upcomingPayments,
                            ),

                            const SizedBox(height: 24),

                            // 6. Cuotas atrasadas
                            OverduePayments(payments: controller.latePayments),

                            const SizedBox(height: 24),

                            // Botón para nuevo crédit

                            const SizedBox(height: 20),
                            
                            // Espacio adicional al final
                            const SizedBox(height: 20),
                          ],
                          
                        ]),
                        
                      ),
                    ),
                  ],
                  
                ),
                
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreditoPage(nombreUsuario: userName ?? "Usuario")),
                    );
                  },
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 6,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
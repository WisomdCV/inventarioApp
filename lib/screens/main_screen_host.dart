import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:inventario_app/screens/add_edit_screen.dart';
import 'package:inventario_app/views/product_list_view.dart';
import 'package:inventario_app/views/search_view.dart';

class MainScreenHost extends StatefulWidget {
  const MainScreenHost({super.key});

  @override
  State<MainScreenHost> createState() => _MainScreenHostState();
}

class _MainScreenHostState extends State<MainScreenHost> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const SearchView(),
    const ProductListView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ahora el Scaffold solo contiene el BottomBar en su cuerpo.
    return Scaffold(
      body: BottomBar(
        // El 'child' es el widget flotante. Usamos un Stack para poner el FAB sobre la barra.
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, // Permite que el FAB se salga de los límites
          children: [
            // La barra de navegación como tal
            Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black, // Color negro como en el ejemplo
                borderRadius: BorderRadius.circular(500),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildTabItem(icon: Icons.search, title: "Buscar", index: 0),
                  _buildTabItem(icon: Icons.list_alt, title: "Inventario", index: 1),
                ],
              ),
            ),
            // El FAB posicionado en la parte superior del Stack para que sobresalga
            Positioned(
              top: -25,
              child: FloatingActionButton(
                backgroundColor: Colors.blue, // Color azul como en el ejemplo
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEditScreen()),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        // El 'body' es el contenido principal de la pantalla
        body: (context, controller) => PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
        // Personalización para que se vea como en el ejemplo
        borderRadius: BorderRadius.circular(500),
        width: MediaQuery.of(context).size.width * 0.85,
        barAlignment: Alignment.bottomCenter,
        // Hacemos la barra transparente porque ya le dimos color al Container
        barColor: Colors.transparent, 
        // Desactivamos el ícono de la librería ya que no lo necesitamos
        showIcon: false, 
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentPage == index;
    // Cambiamos los colores para que coincidan con el fondo oscuro
    final color = isSelected ? Colors.white : Colors.grey[600];
    return InkWell(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() {
          _currentPage = index;
        });
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            Text(title, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

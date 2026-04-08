import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const BurritoBarApp());
}

class BurritoBarApp extends StatelessWidget {
  const BurritoBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final payment = Uri.base.queryParameters['payment'];
    final orderId = Uri.base.queryParameters['orderId'];

    if (payment == 'success') {
      cart.clear();
    }

    Widget homePage = const HomePage();

    if (payment == 'success') {
      homePage = PaymentResultPage(
        isSuccess: true,
        orderId: orderId,
      );
    } else if (payment == 'cancelled') {
      homePage = PaymentResultPage(
        isSuccess: false,
        orderId: orderId,
      );
    }

    return MaterialApp(
      title: 'Burrito Bar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
      ),
      home: homePage,
    );
  }
}

class PaymentResultPage extends StatelessWidget {
  final bool isSuccess;
  final String? orderId;

  const PaymentResultPage({
    super.key,
    required this.isSuccess,
    this.orderId,
  });

  Future<void> _goToMenu() async {
    final cleanUrl = Uri.base.replace(queryParameters: {});
    await launchUrl(
      cleanUrl,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSuccess && cart.isNotEmpty) {
      cart.clear();
    }

    final title = isSuccess ? 'Payment Successful' : 'Payment Cancelled';
    final subtitle = isSuccess
        ? 'Your Stripe payment was completed successfully.'
        : 'Your payment was cancelled. You can go back and try again.';
    final icon = isSuccess ? Icons.check_circle : Icons.cancel;
    final iconColor = isSuccess ? Colors.green : Colors.orange;
    final boxColor = isSuccess ? Colors.green.shade50 : Colors.orange.shade50;
    final borderColor = isSuccess ? Colors.green.shade200 : Colors.orange.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Burrito Bar'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 82,
                      color: iconColor,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    if (orderId != null && orderId!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Order ID',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orderId!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _goToMenu,
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Back to Menu'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (isSuccess) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'You can now continue browsing the menu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  final String name;
  final String category;
  final String description;
  final String imagePath;
  final double price;
  final List<String> extras;

  const MenuItem({
    required this.name,
    required this.category,
    required this.description,
    required this.imagePath,
    required this.price,
    this.extras = const [],
  });
}

class CartItem {
  final MenuItem item;
  final List<String> selectedExtras;
  final List<String> selections;
  int quantity;

  CartItem({
    required this.item,
    this.selectedExtras = const [],
    this.selections = const [],
    this.quantity = 1,
  });

  double get totalPrice => item.price * quantity;
}

class OrderData {
  final String orderId;
  final String customerName;
  final String phone;
  final String orderType;
  final String deliverySlot;
  final String suburb;
  final double total;
  final List<Map<String, dynamic>> items;
  final String status;
  final String paymentStatus;

  OrderData({
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.orderType,
    required this.deliverySlot,
    required this.suburb,
    required this.total,
    required this.items,
    this.status = 'Pending',
    this.paymentStatus = 'Pending Payment',
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'phone': phone,
      'orderType': orderType,
      'deliverySlot': deliverySlot,
      'suburb': suburb,
      'total': total,
      'items': items,
      'status': status,
      'paymentStatus': paymentStatus,
    };
  }
}

final List<CartItem> cart = [];
final List<Map<String, dynamic>> testOrders = [];

const String stripeBackendBaseUrl = 'http://localhost:4242';

const List<String> familyDealBurritos = [
  "Grilled Chicken",
  "Slow Cooked Pulled Beef",
  "Regular Cali Pulled Pork",
  "Chili Beef",
  "Crispy Fish",
  "Vege",
  "Plant-Based Pulled Beef",
];

const List<String> familyDealKidsItems = [
  "KIDS Vegi Nachos",
  "KIDS Beef Nachos",
  "KIDS Chicken Nachos",
  "KIDS Vege Burrito",
  "KIDS Beef Burrito",
  "KIDS Chicken Burrito",
  "KIDS Quesadilla",
];

const List<String> familyDealDrinks = [
  "1.25L Solo",
  "1.25L Sunkist",
  "1.25L Pepsi Max",
  "1.25L Pepsi",
];

const List<String> cannedDrinkOptions = [
  "Can Pepsi",
  "Can Pepsi Max",
  "Can Solo",
  "Can Sunkist",
];

const List<String> bottledDrinkOptions = [
  "1.25L Solo",
  "1.25L Sunkist",
  "1.25L Pepsi Max",
  "1.25L Pepsi",
];

const List<String> jarritosOptions = [
  "Watermelon",
  "Mango",
  "Mandarin",
  "Pineapple",
  "Lime",
  "Guava",
  "Mexican Cola",
];

const List<String> allInOneBoxProteins = [
  "Grilled Chicken",
  "Slow cooked Pulled Beef",
  "Regular Cali Pulled Pork",
  "Chili Beef",
  "Crispy Fish",
  "Vegie",
  "Plant-based Pulled Beef",
];

const List<String> spiceOptions = [
  "Mild",
  "Spicy",
];

const List<String> ribSauceOptions = [
  "BBQ Sauce",
  "Spiced BBQ Sauce",
  "Roasted Tomato Salsa",
  "Chipotle Salsa",
  "Buffalo Sauce",
  "Spicy Stinger Salsa",
];

final List<MenuItem> menuItems = [
  const MenuItem(
    name: "Mexican Fries",
    category: "Starters",
    description:
        "Quality McCain SureCrispTM fries with Mexican seasoning and your choice of sauce or salsa.",
    imagePath: "assets/images/mexican_fries.jpg",
    price: 7.95,
    extras: ["Cheese", "Jalapenos", "Extra Sauce"],
  ),
  const MenuItem(
    name: "Jalapeno Poppers",
    category: "Starters",
    description:
        "5 mild jalapeno poppers filled with cream cheese and coated with a golden crumb.",
    imagePath: "assets/images/jalapeno_poppers.jpg",
    price: 13.95,
    extras: ["Ranch Dip", "Extra Cheese"],
  ),
  const MenuItem(
    name: "Southern Fried Tenderloins",
    category: "Starters",
    description:
        "Chicken tenderloins fried to perfection with a crispy coating.",
    imagePath: "assets/images/southern_fried_tenderloins.jpg",
    price: 12.95,
    extras: ["BBQ Sauce", "Chipotle Mayo"],
  ),
  const MenuItem(
    name: "Taquitos",
    category: "Starters",
    description:
        "2 crispy corn tortillas filled with spicy beans and served with guacamole.",
    imagePath: "assets/images/taquitos.jpg",
    price: 12.95,
    extras: ["Guacamole", "Sour Cream"],
  ),
  const MenuItem(
    name: "Onion Rings",
    category: "Starters",
    description: "10 golden battered onion rings. (1672kj)",
    imagePath: "assets/images/onion_rings.jpg",
    price: 10.95,
    extras: ["BBQ Dip", "Spicy Mayo"],
  ),
  const MenuItem(
    name: "Regular Signature Burrito",
    category: "Burritos",
    description:
        "Burrito Bar's twist on tradition, Signature Burritos are a testament to our commitment in bringing bold tex-mex flavours to you.",
    imagePath: "assets/images/regular_signature_burrito.jpg",
    price: 16.95,
    extras: ["Cheese", "Beans", "Rice", "Salsa", "Guacamole", "Sour Cream"],
  ),
  const MenuItem(
    name: "Large Signature Burrito",
    category: "Burritos",
    description:
        "Burrito Bar's twist on tradition, Signature Burritos are a testament to our commitment in bringing bold tex-mex flavours to you.",
    imagePath: "assets/images/large_signature_burrito.jpg",
    price: 19.95,
    extras: ["Cheese", "Beans", "Rice", "Salsa", "Guacamole", "Sour Cream"],
  ),
  const MenuItem(
    name: "Regular California Burrito",
    category: "Burritos",
    description:
        "Replace rice and black beans with Mexican fries, roasted tomato salsa, cheese, pico de gallo, chipotle mayo. All wrapped in a soft flour tortilla.",
    imagePath: "assets/images/regular_california_burrito.jpg",
    price: 16.95,
    extras: ["Cheese", "Fries", "Salsa", "Guacamole"],
  ),
  const MenuItem(
    name: "Large Classic Burrito",
    category: "Burritos",
    description:
        "Classic Burritos come with long white rice, black beans, pico de gallo, roasted tomato salsa and cheese wrapped in a soft flour tortilla.",
    imagePath: "assets/images/large_classic_burrito.jpg",
    price: 12.95,
    extras: ["Cheese", "Rice", "Beans", "Mild Salsa"],
  ),
  const MenuItem(
    name: "All In One Box",
    category: "Combos & Deals",
    description:
        "Reg California Burrito (exclusions apply), Reg Fries, Can Drink or Bottled Water and 2 Churros!",
    imagePath: "assets/images/all_in_one_box.jpg",
    price: 17.95,
  ),
  const MenuItem(
    name: "Family Deal",
    category: "Combos & Deals",
    description:
        "This offer includes any Large Classic, Cali Burrito, or Burrito Bowl (x2), 2 Large Fries, any Kids Burrito, Quesadilla, or Nachos (x2), 1 x 1.25L Pepsi, Pepsi Max, Sunkist or Solo bottled drinks, and 4 Churros with Chocolate Sauce. Any add-ons or additions will incur additional costs, and the offer is not available with any other promotion.",
    imagePath: "assets/images/family_deal.jpg",
    price: 49.95,
  ),
  const MenuItem(
    name: "Regular Deluxe Nachos",
    category: "Nachos & Wraps",
    description:
        "Corn chips served with roasted tomato salsa, black beans, cheese, guacamole, sour cream, pico de gallo.",
    imagePath: "assets/images/regular_deluxe_nachos.jpg",
    price: 15.95,
    extras: ["Cheese", "Jalapenos", "Guacamole", "Sour Cream"],
  ),
  const MenuItem(
    name: "Large Deluxe Nachos",
    category: "Nachos & Wraps",
    description:
        "Corn chips served with roasted tomato salsa, black beans, cheese, guacamole, sour cream, pico de gallo.",
    imagePath: "assets/images/large_deluxe_nachos.jpg",
    price: 19.95,
    extras: ["Cheese", "Jalapenos", "Guacamole", "Sour Cream"],
  ),
  const MenuItem(
    name: "Crispy Wrap",
    category: "Nachos & Wraps",
    description:
        "Toasted tortilla and crispy taco shell with lettuce, pico de gallo, guacamole, melted cheese, roasted tomato salsa and plant-based pulled beef.",
    imagePath: "assets/images/crispy_wrap.jpg",
    price: 16.95,
    extras: ["Cheese", "Mayo", "Salad"],
  ),
  const MenuItem(
    name: "Quesadilla",
    category: "Nachos & Wraps",
    description:
        "Toasted tortillas filled with melted cheese, pico de gallo with your choice of filling and dipping sauce.",
    imagePath: "assets/images/quesadilla.jpg",
    price: 12.95,
    extras: ["Cheese", "Chicken", "Beans", "Salsa"],
  ),
  const MenuItem(
    name: "Wings",
    category: "Wings & Ribs",
    description: "Chicken wings with flavor.",
    imagePath: "assets/images/wings.jpg",
    price: 12.95,
    extras: ["BBQ", "Hot", "Mild"],
  ),
  const MenuItem(
    name: "Southern Fried Wings",
    category: "Wings & Ribs",
    description:
        "Southern fried chicken wings with a delicious crispy coating.",
    imagePath: "assets/images/southern_fried_wings.jpg",
    price: 10.95,
    extras: ["BBQ", "Hot", "Mild"],
  ),
  const MenuItem(
    name: "Beef Ribs and Fries",
    category: "Wings & Ribs",
    description:
        "Succulent beef ribs basted with your choice of signature BBQ sauce, roasted tomato salsa, chipotle salsa, buffalo sauce, or spicy stinger served with a side of Mexican fries.",
    imagePath: "assets/images/beef_ribs_and_fries.jpg",
    price: 46.95,
  ),
  const MenuItem(
    name: "BBQ Half Ribs",
    category: "Wings & Ribs",
    description:
        "Succulent beef ribs basted with your choice of signature BBQ sauce, roasted tomato salsa, chipotle salsa, buffalo sauce, or spicy stinger served with a side of Mexican fries.",
    imagePath: "assets/images/bbq_half_ribs.jpg",
    price: 25.95,
  ),
  const MenuItem(
    name: "Pork Ribs and Fries",
    category: "Wings & Ribs",
    description:
        "12 Hour Slow-Cooked Pork Ribs basted with your choice of BBQ Sauce, spiced BBQ sauce, roasted tomato salsa, chipotle salsa, buffalo sauce or spicy stinger salsa, served with a side of Mexican fries.",
    imagePath: "assets/images/pork_ribs_and_fries.jpg",
    price: 25.95,
  ),
  const MenuItem(
    name: "Beef Torta",
    category: "Burgers",
    description:
        "A toasted bun, sliced cheese, lettuce, pico de gallo, tomato relish and chipotle mayo with a 100% beef patty.",
    imagePath: "assets/images/beef_torta.jpg",
    price: 17.95,
    extras: ["Cheese", "Bacon", "Egg", "Onion", "Pickles"],
  ),
  const MenuItem(
    name: "Deluxe Burger",
    category: "Burgers",
    description:
        "Juicy 100% Aussie Angus beef patty with cheese, crisp lettuce, tomato, onion, smokin mayo, and tomato relish.",
    imagePath: "assets/images/deluxe_burger.jpg",
    price: 16.95,
    extras: ["Cheese", "Bacon", "Egg", "Onion", "Pickles"],
  ),
  const MenuItem(
    name: "Backyard BBQ Burger",
    category: "Burgers",
    description:
        "Juicy 100% Aussie Angus beef patty, bacon, cheese, grilled onions, crisp lettuce, tomato, mustard, smoky BBQ sauce and tomato relish.",
    imagePath: "assets/images/backyard_bbq_burger.jpg",
    price: 19.95,
    extras: ["Cheese", "Bacon", "BBQ Sauce", "Onion"],
  ),
  const MenuItem(
    name: "BE & BA Burger",
    category: "Burgers",
    description:
        "Juicy 100% Aussie Angus beef patty with bacon, cheese, crisp lettuce, tomato, onion, aioli, and tomato relish.",
    imagePath: "assets/images/be_ba_burger.jpg",
    price: 18.95,
    extras: ["Cheese", "Bacon", "Egg"],
  ),
  const MenuItem(
    name: "Coronado Burger",
    category: "Burgers",
    description:
        "Juicy 100% Aussie Angus beef patty, with cheese, crisp lettuce, tomato, onion, jalapenos, guacamole, smokin mayo and tomato relish.",
    imagePath: "assets/images/coronado_burger.jpg",
    price: 18.95,
    extras: ["Cheese", "Onion", "Pickles"],
  ),
  const MenuItem(
    name: "Pork and Bacon Burger",
    category: "Burgers",
    description:
        "Double the pulled pork, with bacon, crisp lettuce, tomato, onion, smokin’ mayo and BBQ sauce.",
    imagePath: "assets/images/pork_and_bacon_burger.jpg",
    price: 18.95,
    extras: ["Cheese", "Bacon", "BBQ Sauce"],
  ),
  const MenuItem(
    name: "Classic Chicken Burger",
    category: "Burgers",
    description:
        "Tender southern fried chicken with cheese, crisp lettuce, tomato, onion, smokin’ mayo and tomato relish.",
    imagePath: "assets/images/classic_chicken_burger.jpg",
    price: 15.95,
    extras: ["Cheese", "Lettuce", "Mayo"],
  ),
  const MenuItem(
    name: "Veggie Garden Burger",
    category: "Burgers",
    description:
        "Vege patty with crisp lettuce, tomato, onion, guacamole, smokin mayo and tomato relish.",
    imagePath: "assets/images/veggie_garden_burger.jpg",
    price: 16.95,
    extras: ["Cheese", "Onion", "Pickles"],
  ),
  const MenuItem(
    name: "Plant Based Pulled Beef",
    category: "Burgers",
    description:
        "Plant-based beef, cheese, lettce, tomato, onion, tomato relish and smokin mayo.",
    imagePath: "assets/images/plant_based_pulled_beef.jpg",
    price: 17.95,
    extras: ["Cheese", "BBQ Sauce", "Onion"],
  ),
  const MenuItem(
    name: "Kids Quesadilla",
    category: "Kids & Sides",
    description:
        "Toasted flour tortilla filled with melted cheese. Served with a side of sour cream.",
    imagePath: "assets/images/kids_quesadilla.jpg",
    price: 8.95,
  ),
  const MenuItem(
    name: "Kids Cheeseburger",
    category: "Kids & Sides",
    description:
        "Juicy beef patty with cheese and tomato sauce in a fresh burger bun.",
    imagePath: "assets/images/kids_cheeseburger.jpg",
    price: 10.95,
  ),
  const MenuItem(
    name: "Kids Chicken Nuggets and Chips",
    category: "Kids & Sides",
    description:
        "6 golden crumbed chicken nuggets served with fries and your choice of sauce.",
    imagePath: "assets/images/kids_chicken_nuggets_and_chips.jpg",
    price: 11.95,
  ),
  const MenuItem(
    name: "Jarritos",
    category: "Drinks",
    description: "Traditional Mexican soft drink with refreshing fruit flavours.",
    imagePath: "assets/images/jarritos.jpg",
    price: 7.95,
  ),
  const MenuItem(
    name: "Canned Drink",
    category: "Drinks",
    description: "Chilled canned soft drink.",
    imagePath: "assets/images/canned_drink.jpg",
    price: 4.95,
  ),
  const MenuItem(
    name: "Bottled Drink",
    category: "Drinks",
    description: "Large bottled soft drink.",
    imagePath: "assets/images/bottled_drink.jpg",
    price: 6.95,
  ),
];

bool areListsEqualIgnoringOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;

  final sortedA = List<String>.from(a)..sort();
  final sortedB = List<String>.from(b)..sort();

  for (int i = 0; i < sortedA.length; i++) {
    if (sortedA[i] != sortedB[i]) return false;
  }
  return true;
}

void addItemToCart({
  required MenuItem item,
  List<String> selectedExtras = const [],
  List<String> selections = const [],
}) {
  for (final cartItem in cart) {
    final sameItemName = cartItem.item.name == item.name;
    final sameExtras =
        areListsEqualIgnoringOrder(cartItem.selectedExtras, selectedExtras);
    final sameSelections =
        areListsEqualIgnoringOrder(cartItem.selections, selections);

    if (sameItemName && sameExtras && sameSelections) {
      cartItem.quantity++;
      return;
    }
  }

  cart.add(
    CartItem(
      item: item,
      selectedExtras: List<String>.from(selectedExtras),
      selections: List<String>.from(selections),
      quantity: 1,
    ),
  );
}

Future<String> saveOrder(OrderData order) async {
  await Future.delayed(const Duration(milliseconds: 400));
  testOrders.insert(0, order.toJson());
  return order.orderId;
}

Future<void> startCheckoutForOrder({
  required BuildContext context,
  required double totalAmount,
  required String orderId,
  required List<Map<String, dynamic>> items,
}) async {
  final successUrl = Uri.base.replace(queryParameters: {
    ...Uri.base.queryParameters,
    'payment': 'success',
    'orderId': orderId,
  }).toString();

  final cancelUrl = Uri.base.replace(queryParameters: {
    ...Uri.base.queryParameters,
    'payment': 'cancelled',
    'orderId': orderId,
  }).toString();

  final response = await http.post(
    Uri.parse('$stripeBackendBaseUrl/create-checkout-session'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'orderId': orderId,
      'totalAmount': totalAmount,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
      'items': items,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Unable to create Stripe checkout session: ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final checkoutUrl = (data['url'] ?? '').toString();

  if (checkoutUrl.isEmpty) {
    throw Exception('Stripe checkout URL was empty');
  }

  final launched = await launchUrl(
    Uri.parse(checkoutUrl),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_self',
  );

  if (!launched && context.mounted) {
    throw Exception('Could not open Stripe Checkout');
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<String> categories = [
    "Starters",
    "Burritos",
    "Combos & Deals",
    "Nachos & Wraps",
    "Wings & Ribs",
    "Burgers",
    "Kids & Sides",
    "Drinks",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Burrito Bar Menu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
              );
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
          ),
        ],
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.deepOrange,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
                if (context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text("${cart.length}"),
            ),
      body: ListView(
        children: categories
            .map((category) => MenuCategorySection(category: category))
            .toList(),
      ),
    );
  }
}

class MenuCategorySection extends StatelessWidget {
  final String category;

  const MenuCategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final items = menuItems.where((item) => item.category == category).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.orange.shade100,
          padding: const EdgeInsets.all(12),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => MenuCard(item: item)),
      ],
    );
  }
}

class MenuCard extends StatelessWidget {
  final MenuItem item;

  const MenuCard({super.key, required this.item});

  Future<void> _handleAddToCart(BuildContext context) async {
    if (item.name == "All In One Box") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => AllInOneBoxPage(menuItem: item),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (item.name == "Family Deal") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyDealPage(menuItem: item),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (item.name == "Jarritos") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => DrinkSelectionPage(
            menuItem: item,
            title: "Choose Jarritos Flavour",
            options: jarritosOptions,
          ),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (item.name == "Canned Drink") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => DrinkSelectionPage(
            menuItem: item,
            title: "Choose Canned Drink",
            options: cannedDrinkOptions,
          ),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (item.name == "Bottled Drink") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => DrinkSelectionPage(
            menuItem: item,
            title: "Choose Bottled Drink",
            options: bottledDrinkOptions,
          ),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (item.name == "Beef Ribs and Fries" ||
        item.name == "BBQ Half Ribs" ||
        item.name == "Pork Ribs and Fries") {
      final selections = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => SingleChoicePage(
            menuItem: item,
            title: "Choose Sauce",
            options: ribSauceOptions,
            label: "Sauce",
          ),
        ),
      );

      if (selections != null && context.mounted) {
        addItemToCart(item: item, selections: selections);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item.name} added to cart"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final selectedExtras = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExtrasPage(menuItem: item),
      ),
    );

    if (selectedExtras != null && context.mounted) {
      addItemToCart(item: item, selectedExtras: selectedExtras);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${item.name} added to cart"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth < 450 ? 140.0 : 170.0;
    final titleSize = screenWidth < 450 ? 17.0 : 19.0;
    final descriptionSize = screenWidth < 450 ? 13.0 : 14.0;
    final priceSize = screenWidth < 450 ? 16.0 : 18.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: imageHeight,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text(
                    "Image not found",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: descriptionSize,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${item.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: priceSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleAddToCart(context),
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExtrasPage extends StatefulWidget {
  final MenuItem menuItem;

  const ExtrasPage({super.key, required this.menuItem});

  @override
  State<ExtrasPage> createState() => _ExtrasPageState();
}

class _ExtrasPageState extends State<ExtrasPage> {
  static const int maxSelection = 6;
  final List<String> selectedExtras = [];

  @override
  Widget build(BuildContext context) {
    final extras = widget.menuItem.extras;

    return Scaffold(
      appBar: AppBar(title: Text(widget.menuItem.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Base Price: \$${widget.menuItem.price.toStringAsFixed(2)}"),
            const SizedBox(height: 16),
            if (extras.isEmpty)
              const Expanded(
                child: Center(
                  child: Text("No extras available for this item."),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: extras.map((extra) {
                    final isSelected = selectedExtras.contains(extra);
                    final disable =
                        !isSelected && selectedExtras.length >= maxSelection;

                    return CheckboxListTile(
                      title: Text(extra),
                      value: isSelected,
                      onChanged: disable
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  selectedExtras.add(extra);
                                } else {
                                  selectedExtras.remove(extra);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
            Text(
              "${selectedExtras.length}/$maxSelection extras selected",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedExtras);
                },
                child: const Text("Add To Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrinkSelectionPage extends StatefulWidget {
  final MenuItem menuItem;
  final String title;
  final List<String> options;

  const DrinkSelectionPage({
    super.key,
    required this.menuItem,
    required this.title,
    required this.options,
  });

  @override
  State<DrinkSelectionPage> createState() => _DrinkSelectionPageState();
}

class _DrinkSelectionPageState extends State<DrinkSelectionPage> {
  late String selectedDrink;

  @override
  void initState() {
    super.initState();
    selectedDrink = widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Price: \$${widget.menuItem.price.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedDrink,
              decoration: const InputDecoration(
                labelText: "Select Drink",
                border: OutlineInputBorder(),
              ),
              items: widget.options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDrink = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, ["Choice: $selectedDrink"]);
                },
                child: const Text("Add Drink To Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SingleChoicePage extends StatefulWidget {
  final MenuItem menuItem;
  final String title;
  final List<String> options;
  final String label;

  const SingleChoicePage({
    super.key,
    required this.menuItem,
    required this.title,
    required this.options,
    required this.label,
  });

  @override
  State<SingleChoicePage> createState() => _SingleChoicePageState();
}

class _SingleChoicePageState extends State<SingleChoicePage> {
  late String selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Price: \$${widget.menuItem.price.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedOption,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
              ),
              items: widget.options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedOption = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, ["${widget.label}: $selectedOption"]);
                },
                child: const Text("Add To Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllInOneBoxPage extends StatefulWidget {
  final MenuItem menuItem;

  const AllInOneBoxPage({super.key, required this.menuItem});

  @override
  State<AllInOneBoxPage> createState() => _AllInOneBoxPageState();
}

class _AllInOneBoxPageState extends State<AllInOneBoxPage> {
  String protein = allInOneBoxProteins.first;
  String spice = spiceOptions.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Build All In One Box")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Price: \$${widget.menuItem.price.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: protein,
              decoration: const InputDecoration(
                labelText: "Protein",
                border: OutlineInputBorder(),
              ),
              items: allInOneBoxProteins
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  protein = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: spice,
              decoration: const InputDecoration(
                labelText: "Spice",
                border: OutlineInputBorder(),
              ),
              items: spiceOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  spice = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, [
                    "Protein: $protein",
                    "Spice: $spice",
                  ]);
                },
                child: const Text("Add All In One Box To Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyDealPage extends StatefulWidget {
  final MenuItem menuItem;

  const FamilyDealPage({super.key, required this.menuItem});

  @override
  State<FamilyDealPage> createState() => _FamilyDealPageState();
}

class _FamilyDealPageState extends State<FamilyDealPage> {
  String burrito1 = familyDealBurritos.first;
  String burrito2 = familyDealBurritos.first;
  String kids1 = familyDealKidsItems.first;
  String kids2 = familyDealKidsItems.first;
  String drink = familyDealDrinks.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Build Family Deal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Price: \$${widget.menuItem.price.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: burrito1,
              decoration: const InputDecoration(
                labelText: "1st Choice",
                border: OutlineInputBorder(),
              ),
              items: familyDealBurritos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  burrito1 = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: burrito2,
              decoration: const InputDecoration(
                labelText: "2nd Choice",
                border: OutlineInputBorder(),
              ),
              items: familyDealBurritos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  burrito2 = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: kids1,
              decoration: const InputDecoration(
                labelText: "Kids Item 1",
                border: OutlineInputBorder(),
              ),
              items: familyDealKidsItems
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  kids1 = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: kids2,
              decoration: const InputDecoration(
                labelText: "Kids Item 2",
                border: OutlineInputBorder(),
              ),
              items: familyDealKidsItems
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  kids2 = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: drink,
              decoration: const InputDecoration(
                labelText: "1.25L Bottle Drink",
                border: OutlineInputBorder(),
              ),
              items: familyDealDrinks
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  drink = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, [
                    "1st Choice: $burrito1",
                    "2nd Choice: $burrito2",
                    "Kids Item 1: $kids1",
                    "Kids Item 2: $kids2",
                    "Drink: $drink",
                  ]);
                },
                child: const Text("Add Family Deal To Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String orderType = "Delivery";
  String deliverySlot = "12:00 PM";
  String suburb = "0810";

  final double minimumOrder = 80.0;
  final List<String> deliverySlots = ["12:00 PM", "6:00 PM", "8:30 PM"];
  final List<String> suburbs = ["0810", "0812"];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isSubmitting = false;

  double get total => cart.fold(0, (sum, cartItem) => sum + cartItem.totalPrice);

  List<Map<String, dynamic>> buildOrderItems() {
    return cart.map((cartItem) {
      return {
        'name': cartItem.item.name,
        'price': cartItem.item.price,
        'quantity': cartItem.quantity,
        'selectedExtras': cartItem.selectedExtras,
        'selections': cartItem.selections,
        'lineTotal': cartItem.totalPrice,
      };
    }).toList();
  }

  Future<void> placeOrderAndPay() async {
    final customerName = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    final phoneDigitsOnly = RegExp(r'^[0-9]+$');
    if (!phoneDigitsOnly.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must contain digits only'),
        ),
      );
      return;
    }

    final aussieMobile = RegExp(r'^04\d{8}$');
    if (!aussieMobile.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid Australian mobile number'),
        ),
      );
      return;
    }

    final bool deliveryBlocked = orderType == "Delivery" && total < minimumOrder;
    if (deliveryBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum order for delivery is \$${minimumOrder.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final orderId = 'TEST-${DateTime.now().millisecondsSinceEpoch}';
      final orderItems = buildOrderItems();

      final order = OrderData(
        orderId: orderId,
        customerName: customerName,
        phone: phone,
        orderType: orderType,
        deliverySlot: deliverySlot,
        suburb: orderType == "Delivery" ? suburb : "",
        total: total,
        items: orderItems,
      );

      final savedOrderId = await saveOrder(order);

      await startCheckoutForOrder(
        context: context,
        totalAmount: total,
        orderId: savedOrderId,
        items: orderItems,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool deliveryBlocked = orderType == "Delivery" && total < minimumOrder;
    final double amountNeeded = deliveryBlocked ? (minimumOrder - total) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final cartItem = cart[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (cartItem.selectedExtras.isNotEmpty)
                                  Text(
                                    "Extras: ${cartItem.selectedExtras.join(', ')}",
                                  ),
                                if (cartItem.selections.isNotEmpty)
                                  Text(
                                    "Choices: ${cartItem.selections.join(', ')}",
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "\$${cartItem.totalPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              if (cartItem.quantity > 1) {
                                                cartItem.quantity--;
                                              } else {
                                                cart.removeAt(index);
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.remove_circle),
                                        ),
                                        Text(
                                          "${cartItem.quantity}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              cartItem.quantity++;
                                            });
                                          },
                                          icon: const Icon(Icons.add_circle),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Total: \$${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      hintText: "0412345678",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: orderType,
                    decoration: const InputDecoration(
                      labelText: "Order Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Delivery",
                        child: Text("Delivery"),
                      ),
                      DropdownMenuItem(
                        value: "Pickup",
                        child: Text("Pickup"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        orderType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: deliverySlot,
                    decoration: InputDecoration(
                      labelText:
                          orderType == "Delivery" ? "Delivery Slot" : "Pickup Time",
                      border: const OutlineInputBorder(),
                    ),
                    items: deliverySlots
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        deliverySlot = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (orderType == "Delivery") ...[
                    DropdownButtonFormField<String>(
                      initialValue: suburb,
                      decoration: const InputDecoration(
                        labelText: "Suburb / Postcode",
                        border: OutlineInputBorder(),
                      ),
                      items: suburbs
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          suburb = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (deliveryBlocked)
                      Text(
                        "Add \$${amountNeeded.toStringAsFixed(2)} more to reach the delivery minimum of \$${minimumOrder.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      'Stripe checkout opens in the browser and returns to this app after payment.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : placeOrderAndPay,
                      child: Text(
                        isSubmitting ? "Processing..." : "Pay with Stripe",
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<dynamic> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      orders = List<dynamic>.from(testOrders);
      loading = false;
    });
  }

  Future<void> updateStatus(String orderId, String status) async {
    for (final order in testOrders) {
      if (order['orderId'] == orderId) {
        order['status'] = status;
        break;
      }
    }
    await loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Orders")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text("No orders found"))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order #${order['orderId']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text("Customer: ${order['customerName']}"),
                            Text("Phone: ${order['phone']}"),
                            Text("Type: ${order['orderType']}"),
                            Text("Time: ${order['deliverySlot']}"),
                            if ((order['suburb'] ?? '').toString().isNotEmpty)
                              Text("Suburb: ${order['suburb']}"),
                            Text("Status: ${order['status'] ?? 'Pending'}"),
                            Text("Payment: ${order['paymentStatus'] ?? 'Pending Payment'}"),
                            Text(
                              "Total: \$${(order['total'] as num).toStringAsFixed(2)}",
                            ),
                            const SizedBox(height: 8),
                            ...(order['items'] as List).map((item) {
                              final line = item as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text("${line['quantity']} x ${line['name']}"),
                              );
                            }),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      updateStatus(order['orderId'], 'Accepted'),
                                  child: const Text("Accept"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      updateStatus(order['orderId'], 'Preparing'),
                                  child: const Text("Preparing"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      updateStatus(order['orderId'], 'Completed'),
                                  child: const Text("Completed"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

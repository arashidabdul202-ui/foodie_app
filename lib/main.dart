import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodieApp());
}

const orange = Color(0xFFE76F00);
const cream = Color(0xFFFFFBF6);
const adminEmail = 'admin@foodie.com';
const adminPassword = 'admin123';

class FoodieApp extends StatefulWidget {
  const FoodieApp({super.key});

  @override
  State<FoodieApp> createState() => _FoodieAppState();
}

class _FoodieAppState extends State<FoodieApp> {
  bool loading = true;
  String? currentEmail;
  String? currentName;
  bool isAdmin = false;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> orders = [];

  final List<Map<String, dynamic>> foods = [
    {
      'name': 'Jollof Rice',
      'category': 'Rice',
      'price': 2500,
      'rating': '4.8',
      'image':
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=700',
    },
    {
      'name': 'Fried Chicken',
      'category': 'Chicken',
      'price': 3500,
      'rating': '4.9',
      'image':
          'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=700',
    },
    {
      'name': 'Pizza',
      'category': 'Pizza',
      'price': 5000,
      'rating': '4.7',
      'image':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=700',
    },
    {
      'name': 'Cheese Burger',
      'category': 'Burgers',
      'price': 4000,
      'rating': '4.8',
      'image':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=700',
    },
    {
      'name': 'French Fries',
      'category': 'Chips',
      'price': 2000,
      'rating': '4.6',
      'image':
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=700',
    },
    {
      'name': 'Spaghetti',
      'category': 'Spaghetti',
      'price': 3000,
      'rating': '4.7',
      'image':
          'https://images.unsplash.com/photo-1556761223-4c4282c73f77?w=700',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    users = (jsonDecode(prefs.getString('foodie_users') ?? '[]') as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    orders = (jsonDecode(prefs.getString('foodie_orders') ?? '[]') as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    currentEmail = prefs.getString('foodie_email');
    currentName = prefs.getString('foodie_name');
    isAdmin = prefs.getBool('foodie_admin') ?? false;
    if (currentEmail == adminEmail) isAdmin = true;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foodie_users', jsonEncode(users));
    await prefs.setString('foodie_orders', jsonEncode(orders));
  }

  Future<void> _setSession(String email, String name, bool admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foodie_email', email);
    await prefs.setString('foodie_name', name);
    await prefs.setBool('foodie_admin', admin);
    setState(() {
      currentEmail = email;
      currentName = name;
      isAdmin = admin;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foodie_email');
    await prefs.remove('foodie_name');
    await prefs.remove('foodie_admin');
    setState(() {
      currentEmail = null;
      currentName = null;
      isAdmin = false;
    });
  }

  Future<String?> _register(String name, String email, String password) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      return 'Cika dukkan bayanai. Password ya zama aƙalla haruffa 6.';
    }
    if (users.any((u) => u['email'] == email.trim().toLowerCase())) {
      return 'An riga an yi amfani da wannan email.';
    }
    users.add({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await _save();
    await _setSession(email.trim().toLowerCase(), name.trim(), false);
    return null;
  }

  Future<String?> _login(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (e == adminEmail && password == adminPassword) {
      await _setSession(adminEmail, 'Foodie Admin', true);
      return null;
    }
    for (final u in users) {
      if (u['email'] == e && u['password'] == password) {
        await _setSession(e, u['name'].toString(), false);
        return null;
      }
    }
    return 'Email ko password ba daidai ba ne.';
  }

  Future<void> _placeOrder(
    List<Map<String, dynamic>> items,
    int total,
    String paymentMethod,
    String address,
  ) async {
    final order = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'customer': currentName ?? 'Customer',
      'email': currentEmail ?? '',
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'Cash on Delivery'
          ? 'Pending'
          : 'Awaiting confirmation',
      'address': address,
      'status': 'Pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    orders.insert(0, order);
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _updateOrder(String id, String status) async {
    final index = orders.indexWhere((o) => o['id'].toString() == id);
    if (index != -1) {
      orders[index]['status'] = status;
      if (status == 'Delivered') orders[index]['paymentStatus'] = 'Paid';
      await _save();
      setState(() {});
    }
  }

  Future<void> _confirmPayment(String id) async {
    final index = orders.indexWhere((o) => o['id'].toString() == id);
    if (index != -1) {
      orders[index]['paymentStatus'] = 'Paid';
      await _save();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foodie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: orange),
        scaffoldBackgroundColor: cream,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: cream),
      ),
      home: loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator(color: orange)),
            )
          : currentEmail == null
          ? AuthPage(onLogin: _login, onRegister: _register)
          : isAdmin
          ? AdminPage(
              orders: orders,
              onUpdate: _updateOrder,
              onConfirmPayment: _confirmPayment,
              onLogout: _logout,
            )
          : CustomerPage(
              name: currentName ?? 'Customer',
              email: currentEmail!,
              foods: foods,
              orders: orders.where((o) => o['email'] == currentEmail).toList(),
              onPlaceOrder: _placeOrder,
              onLogout: _logout,
            ),
    );
  }
}

class AuthPage extends StatefulWidget {
  final Future<String?> Function(String, String) onLogin;
  final Future<String?> Function(String, String, String) onRegister;
  const AuthPage({super.key, required this.onLogin, required this.onRegister});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool register = false;
  bool busy = false;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> submit() async {
    setState(() => busy = true);
    final error = register
        ? await widget.onRegister(name.text, email.text, password.text)
        : await widget.onLogin(email.text, password.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.fastfood, size: 70, color: orange),
                const SizedBox(height: 8),
                const Text(
                  'Foodie 🍔',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  register ? 'Create your account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (register) _field(name, 'Full name', Icons.person),
                _field(email, 'Email address', Icons.email),
                _field(password, 'Password', Icons.lock, obscure: true),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.all(15),
                  ),
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(register ? 'Create Account' : 'Login'),
                ),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Already have an account? Login'
                        : 'New customer? Create account',
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Admin demo login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Email: admin@foodie.com'),
                        Text('Password: admin123'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class CustomerPage extends StatefulWidget {
  final String name, email;
  final List<Map<String, dynamic>> foods, orders;
  final Future<void> Function(List<Map<String, dynamic>>, int, String, String)
  onPlaceOrder;
  final Future<void> Function() onLogout;
  const CustomerPage({
    super.key,
    required this.name,
    required this.email,
    required this.foods,
    required this.orders,
    required this.onPlaceOrder,
    required this.onLogout,
  });

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  String category = 'All';
  String search = '';
  final Map<String, int> cart = {};
  final categories = [
    'All',
    'Rice',
    'Chicken',
    'Pizza',
    'Burgers',
    'Chips',
    'Spaghetti',
  ];

  int get count => cart.values.fold(0, (a, b) => a + b);
  int get total => cart.entries.fold(0, (sum, e) {
    final f = widget.foods.firstWhere((x) => x['name'] == e.key);
    return sum + (f['price'] as int) * e.value;
  });

  String money(int n) =>
      '₦${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  void add(Map<String, dynamic> food) {
    setState(
      () => cart[food['name'] as String] = (cart[food['name']] ?? 0) + 1,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food['name']} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          foods: widget.foods,
          cart: cart,
          money: money,
          onChanged: () => setState(() {}),
          onCheckout: (items, amount, method, address) async {
            await widget.onPlaceOrder(items, amount, method, address);
            if (mounted) setState(() => cart.clear());
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.foods
        .where(
          (f) =>
              (category == 'All' || f['category'] == category) &&
              f['name'].toString().toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Foodie 🍔',
          style: TextStyle(color: orange, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'My orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderHistoryPage(orders: widget.orders, money: money),
              ),
            ),
            icon: const Icon(Icons.receipt_long),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: openCart,
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (count > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hello, ${widget.name}!',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          const Text(
            'Delicious Food',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Order your favourite food here!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: 'Search for food...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Food Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        selectedColor: orange,
                        labelStyle: TextStyle(
                          color: category == c ? Colors.white : Colors.black,
                        ),
                        onSelected: (_) => setState(() => category = c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Popular Foods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('No food found.'),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .68,
            ),
            itemBuilder: (_, i) {
              final f = filtered[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.network(
                          f['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.fastfood,
                            size: 55,
                            color: orange,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 15,
                                color: Colors.orange,
                              ),
                              Text(' ${f['rating']}'),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  money(f['price']),
                                  style: const TextStyle(
                                    color: orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => add(f),
                              child: const Text('Add to Cart'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderHistoryPage(orders: widget.orders, money: money),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('View Order History'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> foods;
  final Map<String, int> cart;
  final String Function(int) money;
  final VoidCallback onChanged;
  final Future<void> Function(List<Map<String, dynamic>>, int, String, String)
  onCheckout;
  const CartPage({
    super.key,
    required this.foods,
    required this.cart,
    required this.money,
    required this.onChanged,
    required this.onCheckout,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String payment = 'Cash on Delivery';
  final address = TextEditingController();
  bool busy = false;

  int get total => widget.cart.entries.fold(0, (sum, e) {
    final f = widget.foods.firstWhere((x) => x['name'] == e.key);
    return sum + (f['price'] as int) * e.value;
  });

  List<Map<String, dynamic>> get items => widget.cart.entries.map((e) {
    final f = widget.foods.firstWhere((x) => x['name'] == e.key);
    return {
      'name': f['name'],
      'price': f['price'],
      'quantity': e.value,
      'image': f['image'],
    };
  }).toList();

  Future<void> checkout() async {
    if (widget.cart.isEmpty) return;
    if (address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          'Your total is ${widget.money(total)}. Place this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    await widget.onCheckout(items, total, payment, address.text.trim());
    if (!mounted) return;
    setState(() => busy = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your order has been placed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Shopping Cart')),
      body: widget.cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 75,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your cart is empty!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      ...widget.cart.entries.map((e) {
                        final f = widget.foods.firstWhere(
                          (x) => x['name'] == e.key,
                        );
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                f['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.fastfood),
                              ),
                            ),
                            title: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              widget.money((f['price'] as int) * e.value),
                            ),
                            trailing: SizedBox(
                              width: 125,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (e.value > 1) {
                                          widget.cart[e.key] = e.value - 1;
                                        } else {
                                          widget.cart.remove(e.key);
                                        }
                                      });
                                      widget.onChanged();
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text('${e.value}'),
                                  IconButton(
                                    onPressed: () {
                                      setState(
                                        () => widget.cart[e.key] = e.value + 1,
                                      );
                                      widget.onChanged();
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'Delivery Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full delivery address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        value: 'Cash on Delivery',
                        groupValue: payment,
                        title: const Text('Cash on Delivery'),
                        onChanged: (v) => setState(() => payment = v!),
                      ),
                      RadioListTile<String>(
                        value: 'Bank Transfer / Online',
                        groupValue: payment,
                        title: const Text('Bank Transfer / Online (demo)'),
                        onChanged: (v) => setState(() => payment = v!),
                      ),
                      if (payment == 'Bank Transfer / Online')
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Demo mode: submit your order, then contact the admin to confirm your transfer. No real online payment is processed.',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(18),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.money(total),
                              style: const TextStyle(
                                fontSize: 22,
                                color: orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                            ),
                            onPressed: busy ? null : checkout,
                            child: busy
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Place Order'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class OrderHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String Function(int) money;
  const OrderHistoryPage({
    super.key,
    required this.orders,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Order History')),
      body: orders.isEmpty
          ? const Center(child: Text('You have not placed any orders yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                final items = (o['items'] as List)
                    .map((x) => '${x['name']} x${x['quantity']}')
                    .join(', ');
                return Card(
                  color: Colors.white,
                  child: ExpansionTile(
                    title: Text(
                      'Order #${o['id'].toString().substring(o['id'].toString().length - 6)}',
                    ),
                    subtitle: Text(
                      '${money(o['total'] as int)} • ${o['status']}',
                    ),
                    children: [
                      ListTile(
                        title: const Text('Items'),
                        subtitle: Text(items),
                      ),
                      ListTile(
                        title: const Text('Payment'),
                        subtitle: Text(
                          '${o['paymentMethod']} — ${o['paymentStatus']}',
                        ),
                      ),
                      ListTile(
                        title: const Text('Delivery address'),
                        subtitle: Text(o['address'] ?? 'Not provided'),
                      ),
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text(
                          o['createdAt'].toString().replaceFirst('T', ' '),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AdminPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Future<void> Function(String, String) onUpdate;
  final Future<void> Function(String) onConfirmPayment;
  final Future<void> Function() onLogout;
  const AdminPage({
    super.key,
    required this.orders,
    required this.onUpdate,
    required this.onConfirmPayment,
    required this.onLogout,
  });

  String money(int n) =>
      '₦${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o['status'] == 'Pending').length;
    final preparing = orders.where((o) => o['status'] == 'Preparing').length;
    final delivered = orders.where((o) => o['status'] == 'Delivered').length;
    final revenue = orders
        .where((o) => o['status'] == 'Delivered')
        .fold<int>(0, (sum, o) => sum + (o['total'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _stat(
                'Total Orders',
                '${orders.length}',
                Icons.receipt_long,
                Colors.blue,
              ),
              _stat('Pending', '$pending', Icons.pending_actions, orange),
              _stat('Preparing', '$preparing', Icons.restaurant, Colors.purple),
              _stat(
                'Delivered',
                '$delivered',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.payments, color: Colors.green),
              title: const Text('Delivered sales'),
              trailing: Text(
                money(revenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Customer Orders',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: Text('No orders yet.')),
            ),
          ...orders.map((o) {
            final itemText = (o['items'] as List)
                .map((x) => '${x['name']} x${x['quantity']}')
                .join(', ');
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${o['id'].toString().substring(o['id'].toString().length - 6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          money(o['total'] as int),
                          style: const TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text('Customer: ${o['customer']}'),
                    Text('Email: ${o['email']}'),
                    Text('Items: $itemText'),
                    Text('Address: ${o['address']}'),
                    Text('Payment: ${o['paymentMethod']}'),
                    Text('Payment status: ${o['paymentStatus']}'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue:
                          [
                            'Pending',
                            'Preparing',
                            'Delivered',
                            'Cancelled',
                          ].contains(o['status'])
                          ? o['status']
                          : 'Pending',
                      decoration: const InputDecoration(
                        labelText: 'Update order status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Pending', 'Preparing', 'Delivered', 'Cancelled']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onUpdate(o['id'].toString(), v);
                      },
                    ),
                    if (o['paymentStatus'] != 'Paid')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => onConfirmPayment(o['id'].toString()),
                          icon: const Icon(Icons.verified, color: Colors.green),
                          label: const Text('Confirm payment received'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

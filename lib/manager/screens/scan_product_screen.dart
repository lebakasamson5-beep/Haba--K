import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/manager_service.dart';
import '../models/product.dart';

/// Fast, user-friendly barcode scanning screen.
///
/// Key improvements over the original:
/// - Restricts barcode formats to common retail codes -> much faster detection.
/// - Debounces duplicate scans (same code within 2s is ignored).
/// - Pauses the camera the instant a code is found (saves battery, avoids
///   scanning the same/another code while the sheet is open) and resumes
///   automatically when the user is done.
/// - Haptic feedback on every successful scan (no extra audio package needed).
/// - Torch (flash) and front/back camera toggle for low light / awkward angles.
/// - Manual barcode entry fallback for damaged/unreadable codes.
/// - Bottom-sheet workflow: found products show a quick "restock" stepper
///   instead of forcing you to retype everything; new products get a short
///   entry form with a Quantity field.
/// - Session history of the last few scans as tappable chips for fast re-edit.
class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final ManagerService _managerService = ManagerService();

  late final MobileScannerController _scannerController;
  CameraFacing _facing = CameraFacing.back;
  bool _torchOn = false;

  bool _isProcessing = false;
  String? _lastCode;
  DateTime? _lastScanTime;

  final List<Product> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      // Restricting formats to what a shop actually uses makes detection
      // noticeably faster than scanning for every possible format.
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 250,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Scanning
  // ---------------------------------------------------------------------

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Ignore the exact same code if it was scanned in the last 2 seconds.
    final now = DateTime.now();
    if (code == _lastCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastCode = code;
    _lastScanTime = now;

    _handleScannedCode(code);
  }

  Future<void> _handleScannedCode(String code) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    await _scannerController.stop(); // pause camera while we work

    Product? product;
    try {
      product = await _managerService.getProductByBarcode(code);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lookup failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    if (!mounted) return;

    await _openProductSheet(barcode: code, existing: product);

    if (!mounted) return;
    // Resume scanning once the sheet is dismissed.
    await _scannerController.start();
    setState(() => _isProcessing = false);
  }

  Future<void> _openProductSheet({
    required String barcode,
    Product? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ProductSheet(
          barcode: barcode,
          existing: existing,
          managerService: _managerService,
          onSaved: (savedProduct) {
            setState(() {
              _recentScans.removeWhere((p) => p.barcode == savedProduct.barcode);
              _recentScans.insert(0, savedProduct);
              if (_recentScans.length > 6) _recentScans.removeLast();
            });
          },
        );
      },
    );
  }

  Future<void> _manualEntry() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter barcode manually'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 6009123456789',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Look up'),
          ),
        ],
      ),
    );

    if (code != null && code.trim().isNotEmpty && !_isProcessing) {
      _lastCode = null; // allow it even if it matches the last scanned code
      _handleScannedCode(code.trim());
    }
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _scannerController.switchCamera();
    setState(() {
      _facing = _facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
    });
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
          IconButton(
            tooltip: 'Enter barcode manually',
            icon: const Icon(Icons.keyboard),
            onPressed: _manualEntry,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Camera preview ---
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Focus box overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.amber : Colors.greenAccent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.35),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text('Looking up product...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  )
                else
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Point the camera at a barcode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Recent scans ---
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _recentScans.isEmpty
                  ? const Center(
                child: Text(
                  'Products you scan this session will appear here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent scans',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _recentScans.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final p = _recentScans[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green),
                          title: Text(p.name),
                          subtitle: Text(
                              '${p.barcode} • Qty: ${p.quantity} • TSh ${p.price.toStringAsFixed(0)}'),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: _isProcessing
                              ? null
                              : () => _openProductSheet(
                              barcode: p.barcode, existing: p),
                        );
                      },
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

// ===========================================================================
// Bottom sheet: quick restock for existing products, short form for new ones
// ===========================================================================

class _ProductSheet extends StatefulWidget {
  final String barcode;
  final Product? existing;
  final ManagerService managerService;
  final ValueChanged<Product> onSaved;

  const _ProductSheet({
    required this.barcode,
    required this.existing,
    required this.managerService,
    required this.onSaved,
  });

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  String _category = 'Snacks';
  bool _isSaving = false;
  bool _editDetails = false; // for existing products: edit name/price/category

  static const _categories = [
    ('Snacks', '🍿'),
    ('Beverages', '🥤'),
    ('Food', '🍔'),
    ('Electronics', '📱'),
    ('Stationery', '📝'),
    ('Other', '📦'),
  ];

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    // For an existing product default the quantity field to "1" -> the amount
    // being ADDED to stock, not the current stock level.
    _qtyController = TextEditingController(text: _isNew ? '1' : '1');
    _category = p?.category ?? 'Snacks';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final addedQty = int.tryParse(_qtyController.text) ?? 0;

      final Product product;
      if (_isNew) {
        product = Product(
          id: now.millisecondsSinceEpoch.toString(),
          barcode: widget.barcode,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          quantity: addedQty,
          category: _category,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        final existing = widget.existing!;
        product = Product(
          id: existing.id,
          barcode: existing.barcode,
          name: _editDetails ? _nameController.text.trim() : existing.name,
          price: _editDetails ? double.parse(_priceController.text) : existing.price,
          quantity: existing.quantity + addedQty,
          category: _editDetails ? _category : existing.category,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
      }

      // addProduct is expected to upsert (create or overwrite by id).
      // If ManagerService exposes a dedicated update method, prefer that:
      // existing == null ? addProduct : updateProduct
      await widget.managerService.addProduct(product);

      HapticFeedback.lightImpact();
      Fluttertoast.showToast(
        msg: _isNew
            ? '✅ Saved: ${product.name}'
            : '✅ Stock updated: ${product.name} (+$addedQty)',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      widget.onSaved(product);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error saving product: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _stepQty(int delta) {
    final current = int.tryParse(_qtyController.text) ?? 1;
    final next = (current + delta).clamp(1, 9999);
    setState(() => _qtyController.text = next.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    _isNew ? Icons.add_box : Icons.check_circle,
                    color: _isNew ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isNew ? 'New product' : 'Product found',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Barcode: ${widget.barcode}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              if (!_isNew && !_editDetails) ...[
                // Compact read-only summary for a known product.
                _InfoRow(label: 'Name', value: widget.existing!.name),
                _InfoRow(label: 'Category', value: widget.existing!.category),
                _InfoRow(label: 'Price', value: 'TSh ${widget.existing!.price.toStringAsFixed(0)}'),
                _InfoRow(label: 'Current stock', value: '${widget.existing!.quantity}'),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _editDetails = true),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit details'),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _nameController,
                  autofocus: _isNew,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.production_quantity_limits),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter product name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (TSh)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter price';
                    if (double.tryParse(v) == null) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                    value: c.$1,
                    child: Text('${c.$2} ${c.$1}'),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? _category),
                ),
              ],

              const SizedBox(height: 16),

              // Quantity stepper — for new items it's the starting stock,
              // for existing items it's how much is being added.
              Text(
                _isNew ? 'Starting quantity' : 'Quantity to add',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _stepQty(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: _qtyController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return '';
                        return null;
                      },
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _stepQty(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    _isNew ? 'Save New Product' : 'Update Stock',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
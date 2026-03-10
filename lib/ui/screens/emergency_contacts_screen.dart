import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  // ─── Design tokens ────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceSecondary = Color(0xFFF0F2F8);
  static const _accent = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactProvider>(context, listen: false).fetchContacts();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Consumer<ContactProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 1.5,
                      ),
                    );
                  }

                  final contacts = provider.allContacts;

                  if (contacts.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Tách thành 2 nhóm
                  final officialContacts =
                  contacts.where((c) => !c.isCustom).toList();
                  final customContacts =
                  contacts.where((c) => c.isCustom).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (officialContacts.isNotEmpty) ...[
                        _SectionLabel(label: "SỐ KHẨN CẤP"),
                        const SizedBox(height: 10),
                        _buildContactCard(officialContacts, provider),
                        const SizedBox(height: 28),
                      ],
                      if (customContacts.isNotEmpty) ...[
                        Row(
                          children: [
                            const _SectionLabel(label: "NGƯỜI THÂN"),
                            const Spacer(),
                            Text(
                              "${customContacts.length} liên hệ",
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildContactCard(customContacts, provider),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddFAB(
        onTap: () => _showAddContactDialog(context),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _surface,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Danh bạ khẩn cấp",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "Liên hệ nhanh khi có tình huống khẩn",
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
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
    );
  }

  // ── Contact card group ─────────────────────────────────────────────────
  Widget _buildContactCard(List contacts, ContactProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: List.generate(contacts.length, (i) {
            final contact = contacts[i];
            final isLast = i == contacts.length - 1;
            return Column(
              children: [
                _ContactTile(
                  contact: contact,
                  onCall: () => provider.makeCall(contact.phone),
                  onSms: () => provider.sendEmergencySMS(contact.phone),
                  onDelete: contact.isCustom
                      ? () => provider.deleteContact(contact.id)
                      : null,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    color: const Color(0xFFF1F5F9),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.contacts_outlined,
                color: Color(0xFFE11D48),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Chưa có liên hệ nào",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nhấn nút + bên dưới để thêm\nsố điện thoại người thân.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add contact dialog ─────────────────────────────────────────────────
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    bool isSubmitting = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Color(0xFFE11D48),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Thêm người thân",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                "Liên hệ khi khẩn cấp",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fields
                      _DialogField(
                        controller: nameController,
                        label: "Họ và tên",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: phoneController,
                        label: "Số điện thoại",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _DialogField(
                        controller: relationController,
                        label: "Mối quan hệ (Bố, Mẹ...)",
                        icon: Icons.family_restroom_outlined,
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _surfaceSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _border),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Hủy",
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: isSubmitting
                                  ? null
                                  : () async {
                                if (nameController.text.isEmpty ||
                                    phoneController.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Vui lòng nhập tên và số điện thoại"),
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(
                                        () => isSubmitting = true);
                                final success = await Provider.of<
                                    ContactProvider>(context,
                                    listen: false)
                                    .addContact(
                                    nameController.text,
                                    phoneController.text,
                                    relationController.text);
                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                      content:
                                      Text("Đã thêm liên hệ!")));
                                } else {
                                  setDialogState(
                                          () => isSubmitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                        content: Text(
                                            "Lỗi khi thêm liên hệ")));
                                  }
                                }
                              },
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE11D48)
                                          .withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: isSubmitting
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "Lưu lại",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

// ─── Contact tile ───────────────────────────────────────────────────────────
class _ContactTile extends StatefulWidget {
  final dynamic contact;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback? onDelete;

  const _ContactTile({
    required this.contact,
    required this.onCall,
    required this.onSms,
    this.onDelete,
  });

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCustom = widget.contact.isCustom;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color:
        _pressed ? const Color(0xFFF8FAFF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isCustom
                    ? const Color(0xFFEFF4FF)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCustom ? Icons.person_rounded : Icons.emergency_rounded,
                size: 20,
                color: isCustom
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE11D48),
              ),
            ),
            const SizedBox(width: 14),
            // Name & phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIconButton(
                  icon: Icons.call_rounded,
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFF0FDF4),
                  onTap: widget.onCall,
                ),
                const SizedBox(width: 7),
                _ActionIconButton(
                  icon: Icons.sms_rounded,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF4FF),
                  onTap: widget.onSms,
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 7),
                  _ActionIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFF94A3B8),
                    bg: const Color(0xFFF1F5F9),
                    onTap: widget.onDelete!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small action icon button ───────────────────────────────────────────────
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

// ─── Dialog text field ──────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}

// ─── FAB add button ─────────────────────────────────────────────────────────
class _AddFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFAB({required this.onTap});

  @override
  State<_AddFAB> createState() => _AddFABState();
}

class _AddFABState extends State<_AddFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE11D48),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
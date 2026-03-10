import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/checklist_provider.dart';
import 'profile/profile_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChecklistProvider>(context, listen: false).initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        Provider.of<ChecklistProvider>(context, listen: false).syncDataWithServer();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Consumer<ChecklistProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── APP BAR ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF1A1A2E), size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              "Chuẩn bị ứng phó",
                              style: TextStyle(
                                color: Color(0xFF1A1A2E),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF0F8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded,
                                  color: Color(0xFF4A5568), size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (provider.isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.categories.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text("Không có dữ liệu checklist.",
                              style: TextStyle(color: Color(0xFF9AA0B2))),
                        ),
                      )
                    else ...[
                        // ── PROGRESS ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                          child: _ProgressSection(progress: provider.progress),
                        ),

                        const SizedBox(height: 8),

                        // ── LIST ──
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            itemCount: provider.categories.length,
                            itemBuilder: (context, index) {
                              final category = provider.categories[index];
                              return _CategoryCard(
                                category: category,
                                provider: provider,
                              );
                            },
                          ),
                        ),
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PROGRESS SECTION
// ════════════════════════════════════════════════════════════
class _ProgressSection extends StatelessWidget {
  final double progress;
  const _ProgressSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final isDone = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isDone ? "Hoàn thành tất cả! 🎉" : "Tiến độ chuẩn bị",
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "$pct%",
              style: TextStyle(
                color: isDone
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: isDone
                        ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                        : [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CATEGORY CARD
// ════════════════════════════════════════════════════════════
class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final ChecklistProvider provider;

  const _CategoryCard({required this.category, required this.provider});

  static const _accents = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  Color get _accent =>
      _accents[category.categoryName.hashCode.abs() % _accents.length];

  @override
  Widget build(BuildContext context) {
    final items = category.items as List;
    final done = items
        .where((item) => provider.completedItemIds.contains(item.id))
        .length;
    final total = items.length;
    final allDone = done == total && total > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: allDone ? const Color(0xFF22C55E) : _accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: TextStyle(
                      color: allDone
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: allDone
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    "$done/$total",
                    style: TextStyle(
                      color: allDone
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFF1F5F9),
          ),

          // ── ITEMS ──
          ...items.map<Widget>((item) {
            final isCompleted = provider.completedItemIds.contains(item.id);
            return _ItemRow(
              item: item,
              isCompleted: isCompleted,
              onTap: () => provider.toggleItem(item.id, !isCompleted),
            );
          }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ITEM ROW
// ════════════════════════════════════════════════════════════
class _ItemRow extends StatelessWidget {
  final dynamic item;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ItemRow({
    required this.item,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),

            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: isCompleted
                      ? const Color(0xFFB0BAC9)
                      : const Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration:
                  isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFFB0BAC9),
                ),
              ),
            ),

            // Important chip
            if (item.isImportant)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFFFED7AA), width: 1),
                ),
                child: const Text(
                  "Quan trọng",
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
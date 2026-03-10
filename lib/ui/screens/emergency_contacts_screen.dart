import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactProvider>(context, listen: false).fetchContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh bạ khẩn cấp", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          final contacts = provider.allContacts;
          if (contacts.isEmpty) return const Center(child: Text("Không có liên hệ nào."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: contact.isCustom ? Colors.teal : Colors.red[100],
                    child: Icon(contact.isCustom ? Icons.person : Icons.emergency,
                        color: contact.isCustom ? Colors.white : Colors.red),
                  ),
                  title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(contact.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => provider.makeCall(contact.phone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sms, color: Colors.blue),
                        onPressed: () => provider.sendEmergencySMS(contact.phone),
                      ),
                      if (contact.isCustom)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => provider.deleteContact(contact.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Hàm hiển thị Dialog thêm số điện thoại người thân
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Thêm người thân", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Họ và tên", prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Số điện thoại", prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: relationController,
                      decoration: const InputDecoration(labelText: "Mối quan hệ (Ví dụ: Bố, Mẹ)", prefixIcon: Icon(Icons.family_restroom)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và số điện thoại")));
                      return;
                    }

                    setState(() => isSubmitting = true); // Hiện loading

                    // Gọi hàm thêm ở Provider
                    final success = await Provider.of<ContactProvider>(context, listen: false)
                        .addContact(nameController.text, phoneController.text, relationController.text);

                    if (success && ctx.mounted) {
                      Navigator.pop(ctx); // Đóng hộp thoại nếu thành công
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm liên hệ!")));
                    } else {
                      setState(() => isSubmitting = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm liên hệ")));
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Lưu lại"),
                ),
              ],
            );
          }
      ),
    );
  }
}
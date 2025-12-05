import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/girl_model.dart';
import 'package:magic_dashbord/style/brand_color.dart';
import 'package:toggle_switch/toggle_switch.dart';

class GirlsScreen extends StatefulWidget {
  const GirlsScreen({super.key});

  @override
  State<GirlsScreen> createState() => _GirlsScreenState();
}

class _GirlsScreenState extends State<GirlsScreen> {
  List<GirlModel> _girls = [];
  List<Map<String, dynamic>> _authUsers = [];
  bool _isLoading = false;

  final DbHelper _db = DbHelper();

  @override
  void initState() {
    _fetchdata();
    _fetchAuthUsers();
    super.initState();
  }

  Future<void> _fetchdata() async {
    setState(() => _isLoading = true);
    List<GirlModel> models = await _db.getGirls();
    setState(() {
      _girls = models;
      _isLoading = false;
    });
  }

  Future<void> _fetchAuthUsers() async {
    List<Map<String, dynamic>> authUsers = await _db.getAuthUsers();
    setState(() {
      _authUsers = authUsers;
    });
  }

  Future<void> removeGirl(String id) async {
    _db.removeGirlById(id).then((value) => _fetchdata());
  }

  Future<void> _addGirlFromAuth(Map<String, dynamic> userData) async {
    setState(() => _isLoading = true);
    final result = await _db.addGirlFromAuthUser(userData);
    if (result == 'success') {
      _fetchdata();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Girl added successfully!')),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding girl')),
        );
      }
    }
  }

  Future<void> _addGirlManually(
      String id, String firstName, String lastName, String email,
      [String imageUrl = '']) async {
    setState(() => _isLoading = true);
    final result =
        await _db.addGirlManually(id, firstName, lastName, email, imageUrl);
    if (result == 'success') {
      _fetchdata();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Girl added successfully!')),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $result')),
        );
      }
    }
  }

  void _showAddGirlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose how to add Girl'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualAddDialog();
              },
              child: const Text('Add Girl Manually'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAuthUsersDialog();
              },
              child: const Text('Add from Auth Users'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Girl Manually'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'User ID *',
                  hintText: 'Enter unique user ID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (idController.text.trim().isNotEmpty &&
                  firstNameController.text.trim().isNotEmpty &&
                  lastNameController.text.trim().isNotEmpty &&
                  emailController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _addGirlManually(
                  idController.text.trim(),
                  firstNameController.text.trim(),
                  lastNameController.text.trim(),
                  emailController.text.trim(),
                  imageUrlController.text.trim(),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill all required fields')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAuthUsersDialog() {
    // Фільтруємо користувачів, які ще не додані як Girls
    final availableUsers = _authUsers.where((user) {
      return !_girls.any((girl) => girl.id == user['id']);
    }).toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available users to add from Auth')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Girl from Auth Users'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              final user = availableUsers[index];
              return ListTile(
                leading: user['imageUrl'] != null && user['imageUrl'].isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user['imageUrl']))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                subtitle: Text(user['email'] ?? ''),
                onTap: () {
                  Navigator.of(context).pop();
                  _addGirlFromAuth(user);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Girls Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _showAddGirlDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Girl'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_girls.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Girls: No data available',
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _girls.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                          color: index.isEven
                              ? BrandColor.kRed.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfo(index),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Action'),
                                IconButton(
                                    onPressed: () async {
                                      await removeGirl(_girls[index].id);
                                    },
                                    tooltip: 'Remove girls',
                                    icon: const Icon(
                                      Icons.remove_circle_outline_outlined,
                                      color: Colors.red,
                                    ))
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
            ),
        ],
      ),
    );
  }

  Column _buildInfo(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${_girls[index].firstName} ${_girls[index].lastName} /${_girls[index].email}',
            style:
                const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20.0),
        const Text(
          'ACTIVE:',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4.0),
        ToggleSwitch(
          minWidth: 90.0,
          cornerRadius: 20.0,
          activeBgColors: const [
            [BrandColor.kGreen],
            [BrandColor.kRed]
          ],
          activeFgColor: Colors.white,
          inactiveBgColor: Colors.grey,
          inactiveFgColor: Colors.white,
          initialLabelIndex: _girls[index].isActive ? 0 : 1,
          totalSwitches: 2,
          labels: const ['ON', 'OFF'],
          radiusStyle: true,
          onToggle: (i) async {
            await _db.updateGirlActive(_girls[index].id, i == 0 ? true : false);
          },
        ),
      ],
    );
  }
}

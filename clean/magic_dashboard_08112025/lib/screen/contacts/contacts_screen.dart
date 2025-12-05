import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final DbHelper _db = DbHelper();
  Map<String, Map<String, List<Map<String, dynamic>>>> _allContactsData = {};
  Map<String, DeviceModel> _devices = {};
  bool _isLoading = false;
  String _selectedDeviceId = '';
  String _selectedFolder = '';

  // Local file contacts
  List<Map<String, dynamic>>? _localContacts;
  bool _showingLocalContacts = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // Get devices first
      final devicesStream = _db.fetchDevices();
      final devicesSnapshot = await devicesStream.first;

      // Get all contact folders data
      final contactsData = await _db.getAllContactFoldersData();

      setState(() {
        _devices = devicesSnapshot ?? {};
        _allContactsData = contactsData;
        if (_devices.isNotEmpty && _selectedDeviceId.isEmpty) {
          _selectedDeviceId = _devices.keys.first;
        }
        _selectedFolder = ''; // Reset folder selection when data changes
      });
    } catch (e) {
      print('Error fetching contacts data: $e');

      // Check if it's a quota exceeded error
      if (e.toString().contains('quota-exceeded') ||
          e.toString().contains('Firebase Storage quota exceeded')) {
        // Show quota exceeded error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Firebase Storage quota exceeded. Please contact administrator or try again later.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocalContactsFile() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await _db.pickAndParseContactsFile();

      if (contacts != null && contacts.isNotEmpty) {
        setState(() {
          _localContacts = contacts;
          _showingLocalContacts = true;
          _selectedDeviceId = ''; // Clear device selection
          _selectedFolder = ''; // Clear folder selection
          _searchQuery = '';
          _searchController.clear();
          _updateFilteredContacts();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully loaded ${contacts.length} contacts from file'),
            backgroundColor: BrandColor.kGreen,
          ),
        );
      } else if (contacts != null && contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contacts found in the selected file'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // If contacts is null, user cancelled file selection - no message needed
    } catch (e) {
      print('Error picking local contacts file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearLocalContacts() {
    setState(() {
      _localContacts = null;
      _showingLocalContacts = false;
      _searchQuery = '';
      _searchController.clear();
      _filteredContacts = [];
    });
  }

  void _performSearch(String query) {
    print('🔍 Performing search with query: "$query"');
    print('📱 _showingLocalContacts: $_showingLocalContacts');
    print('📞 _localContacts length: ${_localContacts?.length ?? 0}');

    setState(() {
      _searchQuery = query.toLowerCase();
      _updateFilteredContacts();
    });

    print('📊 Filtered contacts length: ${_filteredContacts.length}');
  }

  void _updateFilteredContacts() {
    List<Map<String, dynamic>> allContacts = [];

    if (_localContacts != null) {
      allContacts = _localContacts!;
      print('📋 Using local contacts: ${allContacts.length}');
    } else if (_selectedDeviceId.isNotEmpty && _selectedFolder.isNotEmpty) {
      final deviceContacts = _allContactsData[_selectedDeviceId];
      if (deviceContacts != null) {
        allContacts = deviceContacts[_selectedFolder] ?? [];
        print('📋 Using Firebase contacts: ${allContacts.length}');
      }
    }

    if (_searchQuery.isEmpty) {
      _filteredContacts = allContacts;
      print('📊 No search query, showing all: ${_filteredContacts.length}');
    } else {
      _filteredContacts = allContacts.where((contact) {
        final name = (contact['name'] ?? '').toString().toLowerCase();
        final firstName = (contact['firstName'] ?? '').toString().toLowerCase();
        final lastName = (contact['lastName'] ?? '').toString().toLowerCase();
        final middleName =
            (contact['middleName'] ?? '').toString().toLowerCase();
        final organization =
            (contact['organization'] ?? '').toString().toLowerCase();

        // Search in phones and emails too
        final phones = List<String>.from(contact['phones'] ?? []);
        final emails = List<String>.from(contact['emails'] ?? []);
        final phoneText = phones.join(' ').toLowerCase();
        final emailText = emails.join(' ').toLowerCase();

        final matches = name.contains(_searchQuery) ||
            firstName.contains(_searchQuery) ||
            lastName.contains(_searchQuery) ||
            middleName.contains(_searchQuery) ||
            organization.contains(_searchQuery) ||
            phoneText.contains(_searchQuery) ||
            emailText.contains(_searchQuery);

        if (matches) {
          print('✅ Match found: ${contact['name']} for query "$_searchQuery"');
        }

        return matches;
      }).toList();
      print('📊 Filtered results: ${_filteredContacts.length}');
    }
  }

  Future<void> _exportContactsToCSV() async {
    try {
      List<Map<String, dynamic>> contactsToExport = [];

      if (_localContacts != null) {
        // Export local contacts
        contactsToExport = _localContacts!;
      } else if (_selectedDeviceId.isNotEmpty && _selectedFolder.isNotEmpty) {
        // Export Firebase contacts from selected folder
        final deviceContacts = _allContactsData[_selectedDeviceId];
        if (deviceContacts != null) {
          contactsToExport = deviceContacts[_selectedFolder] ?? [];
        }
      }

      if (contactsToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contacts to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = _localContacts != null
          ? 'local_contacts_$timestamp'
          : 'contacts_${_selectedDeviceId}_${_selectedFolder}_$timestamp';

      await _db.exportContactsToCSV(contactsToExport, filename);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully exported ${contactsToExport.length} contacts to CSV'),
          backgroundColor: BrandColor.kGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchField(),
          if (_devices.isNotEmpty) _buildDeviceSelector(),
          if (_selectedDeviceId.isNotEmpty) _buildFolderSelector(),
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    // Only show search when we have contacts to search
    final hasContacts = (_showingLocalContacts &&
            _localContacts != null &&
            _localContacts!.isNotEmpty) ||
        (!_showingLocalContacts &&
            _selectedDeviceId.isNotEmpty &&
            _selectedFolder.isNotEmpty);

    if (!hasContacts) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts by name, phone, or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: BrandColor.kRed.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Contacts Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickLocalContactsFile,
                icon: const Icon(Icons.file_upload, size: 18),
                label: const Text('Pick Local File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh contacts',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector() {
    if (_devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No devices found'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Select Device: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedDeviceId.isEmpty ? null : _selectedDeviceId,
              isExpanded: true,
              items: _devices.entries.map((entry) {
                final device = entry.value;
                final foldersCount = _allContactsData[entry.key]?.length ?? 0;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    '${device.info.brand} ${device.info.model} ($foldersCount folders)',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDeviceId = value ?? '';
                  _selectedFolder = ''; // Reset folder selection
                  _showingLocalContacts = false; // Clear local contacts
                  _localContacts = null;
                  _searchQuery = '';
                  _searchController.clear();
                  _filteredContacts = [];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSelector() {
    final deviceFolders = _allContactsData[_selectedDeviceId] ?? {};

    if (deviceFolders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No contact folders found for this device'),
            SizedBox(height: 8),
            Text(
              'This might be due to Firebase Storage quota exceeded. Please check Firebase console.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Select Folder: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFolder.isEmpty ? null : _selectedFolder,
              hint: const Text('Choose a contact folder'),
              isExpanded: true,
              items: deviceFolders.entries.map((entry) {
                final contactCount = entry.value.length;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text('${entry.key} ($contactCount contacts)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFolder = value ?? '';
                  _searchQuery = '';
                  _searchController.clear();
                  _updateFilteredContacts();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show local contacts if they are loaded
    if (_showingLocalContacts && _localContacts != null) {
      // Ensure filtered contacts are updated
      if (_filteredContacts.isEmpty && _searchQuery.isEmpty) {
        _updateFilteredContacts();
      }

      final contactsToShow =
          _filteredContacts.isNotEmpty ? _filteredContacts : _localContacts!;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: BrandColor.kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            margin: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.file_present, color: BrandColor.kGreen),
                const SizedBox(width: 8),
                const Text(
                  'Local File',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  Text(
                    '${contactsToShow.length} of ${_localContacts!.length} contacts',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )
                else
                  Text(
                    '${_localContacts!.length} contacts',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      (_localContacts != null && _localContacts!.isNotEmpty) ||
                              (_selectedDeviceId.isNotEmpty &&
                                  _selectedFolder.isNotEmpty &&
                                  contactsToShow.isNotEmpty)
                          ? _exportContactsToCSV
                          : null,
                  icon: const Icon(Icons.file_download, size: 16),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearLocalContacts,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: contactsToShow.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No contacts found for "$_searchQuery"'
                              : 'No contacts to display',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: contactsToShow.length,
                    itemBuilder: (context, index) {
                      final contact = contactsToShow[index];
                      return _buildContactCard(contact);
                    },
                  ),
          ),
        ],
      );
    }

    // Show Firebase Storage contacts
    if (_selectedDeviceId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a device or pick a local file to view contacts',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_selectedFolder.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a contact folder to view contacts',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final contacts =
        _allContactsData[_selectedDeviceId]?[_selectedFolder] ?? [];

    if (contacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No contacts found in this folder',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Ensure filtered contacts are updated for Firebase contacts
    if (_filteredContacts.isEmpty && _searchQuery.isEmpty) {
      _updateFilteredContacts();
    }

    final contactsToShow =
        _filteredContacts.isNotEmpty ? _filteredContacts : contacts;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: BrandColor.kGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          margin: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: BrandColor.kGreen),
              const SizedBox(width: 8),
              Text(
                'Folder: $_selectedFolder',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty)
                Text(
                  '${contactsToShow.length} of ${contacts.length} contacts',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                )
              else
                Text(
                  '${contacts.length} contacts',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    (_localContacts != null && _localContacts!.isNotEmpty) ||
                            (_selectedDeviceId.isNotEmpty &&
                                _selectedFolder.isNotEmpty &&
                                contactsToShow.isNotEmpty)
                        ? _exportContactsToCSV
                        : null,
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: contactsToShow.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No contacts found for "$_searchQuery"'
                            : 'No contacts to display',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: contactsToShow.length,
                  itemBuilder: (context, index) {
                    final contact = contactsToShow[index];
                    return _buildContactCard(contact);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['name'] ?? 'Unknown';
    final firstName = contact['firstName'] ?? '';
    final lastName = contact['lastName'] ?? '';
    final middleName = contact['middleName'] ?? '';
    final phones = List<String>.from(contact['phones'] ?? []);
    final emails = List<String>.from(contact['emails'] ?? []);
    final organization = contact['organization'];
    final folder = contact['folder'] ?? '';
    final uid = contact['uid'] ?? '';
    final isLocal = contact['isLocal'] == true;
    final source = contact['source'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isLocal ? BrandColor.kGreen : BrandColor.kRed,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show name parts if available (for structured format)
                      if (isLocal &&
                          (firstName.isNotEmpty ||
                              lastName.isNotEmpty ||
                              middleName.isNotEmpty))
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (firstName.isNotEmpty)
                              Chip(
                                label: Text('First: $firstName',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (middleName.isNotEmpty)
                              Chip(
                                label: Text('Middle: $middleName',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green.withOpacity(0.1),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (lastName.isNotEmpty)
                              Chip(
                                label: Text('Last: $lastName',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor: Colors.orange.withOpacity(0.1),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      if (organization != null && organization.isNotEmpty)
                        Text(
                          organization,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (isLocal && source.isNotEmpty)
                        Text(
                          'Source: $source',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isLocal && folder.isNotEmpty && uid.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _db.downloadContactFile(uid, folder);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading contacts file...'),
                            backgroundColor: BrandColor.kGreen,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error downloading file: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColor.kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            if (phones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildContactInfo('Phones', phones, Icons.phone),
            ],
            if (emails.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContactInfo('Emails', emails, Icons.email),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, List<String> values, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: BrandColor.kRed),
            const SizedBox(width: 4),
            Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...values.map((value) => Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 2.0),
              child: SelectableText(
                value,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            )),
      ],
    );
  }
}

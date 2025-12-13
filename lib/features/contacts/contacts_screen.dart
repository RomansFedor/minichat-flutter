import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'models/contact_model.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<ContactModel> _contacts = [
    ContactModel(
      id: '1',
      name: 'Олександр Петренко',
      email: 'oleksandr@example.com',
      isOnline: true,
      status: 'У нагоді',
    ),
    ContactModel(
      id: '2',
      name: 'Марія Коваленко',
      email: 'maria@example.com',
      isOnline: true,
      status: 'Працюю',
    ),
    ContactModel(
      id: '3',
      name: 'Дмитро Іваненко',
      email: 'dmytro@example.com',
      isOnline: false,
      status: null,
    ),
    ContactModel(
      id: '4',
      name: 'Анна Мельник',
      email: 'anna@example.com',
      isOnline: true,
      status: 'Зараз на місці',
    ),
    ContactModel(
      id: '5',
      name: 'Іван Сидоренко',
      email: 'ivan@example.com',
      isOnline: false,
      status: null,
    ),
    ContactModel(
      id: '6',
      name: 'Олена Шевченко',
      email: 'olena@example.com',
      isOnline: true,
      status: 'У нагоді',
    ),
    ContactModel(
      id: '7',
      name: 'Віктор Ткаченко',
      email: 'viktor@example.com',
      isOnline: false,
      status: null,
    ),
    ContactModel(
      id: '8',
      name: 'Наталія Бондаренко',
      email: 'natalia@example.com',
      isOnline: true,
      status: 'Не турбувати',
    ),
    ContactModel(
      id: '9',
      name: 'Андрій Гриценко',
      email: 'andriy@example.com',
      isOnline: true,
      status: 'Працюю',
    ),
    ContactModel(
      id: '10',
      name: 'Юлія Романенко',
      email: 'yulia@example.com',
      isOnline: false,
      status: null,
    ),
  ];

  String _searchQuery = '';
  String _sortBy = 'name'; // 'name' або 'status'

  List<ContactModel> get _filteredAndSortedContacts {
    var filtered = _contacts.where((contact) {
      final query = _searchQuery.toLowerCase();
      return contact.name.toLowerCase().contains(query) ||
          contact.email.toLowerCase().contains(query);
    }).toList();

    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'status') {
      filtered.sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return a.name.compareTo(b.name);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Пошук контактів...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Сортувати:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('За ім\'ям'),
                      selected: _sortBy == 'name',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortBy = 'name';
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('За статусом'),
                      selected: _sortBy == 'status',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortBy = 'status';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAndSortedContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Контакти не знайдені',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredAndSortedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredAndSortedContacts[index];
                      return _buildContactCard(contact);
                    },
                  ),
          ),
        ],
    );
  }

  Widget _buildContactCard(ContactModel contact) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactDetailScreen(contact: contact),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (contact.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                contact.email,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (contact.status != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: contact.isOnline
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.status!,
                    style: TextStyle(
                      fontSize: 10,
                      color: contact.isOnline
                          ? Colors.green[700]
                          : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/cached_image.dart';
import '../../core/services/logger_service.dart';
import '../../core/constants/app_colors.dart';

class ChildrenListScreen extends ConsumerStatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  ConsumerState<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends ConsumerState<ChildrenListScreen> {
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    LoggerService.userAction('children_list_viewed');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChildModel> get _filteredChildren {
    final user = ref.watch(authControllerProvider).userData;
    if (user?.children == null) return [];

    if (_searchQuery.isEmpty) {
      return user!.children;
    }

    return user!.children.where((child) {
      return child.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          child.ageInYears.toString().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final children = _filteredChildren;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Children',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              LoggerService.userAction('children_view_toggled',
                  parameters: {'view_type': _isGridView ? 'grid' : 'list'});
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search children by name or age...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Children Count & Add Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${children.length} ${children.length == 1 ? 'Child' : 'Children'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    LoggerService.userAction('add_child_button_pressed');
                    context.push('/children/add');
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Child'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Children List/Grid
          Expanded(
            child: authState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildGridView(children)
                        : _buildListView(children),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          LoggerService.userAction('add_child_fab_pressed');
          context.push('/children/add');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Children Added Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No children match your search criteria'
                  : 'Add your first child to start booking consultations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  LoggerService.userAction('add_first_child_button_pressed');
                  context.push('/children/add');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Child'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<ChildModel> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return _buildChildGridCard(children[index]);
        },
      ),
    );
  }

  Widget _buildListView(List<ChildModel> children) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildChildListCard(children[index]);
      },
    );
  }

  Widget _buildChildGridCard(ChildModel child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onChildTap(child),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CachedAvatar(
                imageUrl: child.photoUrl ?? '',
                radius: 32,
                placeholder: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _getGenderColor(child.gender).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    child.gender == Gender.male ? Icons.boy : Icons.girl,
                    size: 32,
                    color: _getGenderColor(child.gender),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Age & Gender
              Text(
                '${child.ageInYears} years • ${child.gender.name.capitalize()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Date of Birth
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDate(child.dateOfBirth),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _editChild(child),
                    icon: const Icon(Icons.edit, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _bookConsultation(child),
                    icon: const Icon(Icons.video_call, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildListCard(ChildModel child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onChildTap(child),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CachedAvatar(
                imageUrl: child.photoUrl ?? '',
                radius: 24,
                placeholder: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getGenderColor(child.gender).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    child.gender == Gender.male ? Icons.boy : Icons.girl,
                    size: 24,
                    color: _getGenderColor(child.gender),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${child.ageInYears} years old • ${child.gender.name.capitalize()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Born: ${_formatDate(child.dateOfBirth)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _editChild(child),
                    icon: const Icon(Icons.edit, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: () => _bookConsultation(child),
                    icon: const Icon(Icons.video_call, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _onChildTap(ChildModel child) {
    LoggerService.userAction('child_card_tapped',
        parameters: {'child_id': child.id});
    context.push('/children/edit/${child.id}');
  }

  void _editChild(ChildModel child) {
    LoggerService.userAction('edit_child_button_pressed',
        parameters: {'child_id': child.id});
    context.push('/children/edit/${child.id}');
  }

  void _bookConsultation(ChildModel child) {
    LoggerService.userAction('book_consultation_button_pressed',
        parameters: {'child_id': child.id});
    context.push('/consultation/book', extra: child);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

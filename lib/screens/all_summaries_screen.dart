import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../widgets/summary_card.dart';

class AllSummariesScreen extends StatefulWidget {
  final List<SummaryItem> summaries;

  const AllSummariesScreen({super.key, required this.summaries});

  @override
  State<AllSummariesScreen> createState() => _AllSummariesScreenState();
}

class _AllSummariesScreenState extends State<AllSummariesScreen> {
  SummaryType? _selectedType;
  String _searchQuery = '';
  late List<SummaryItem> _filteredSummaries;

  @override
  void initState() {
    super.initState();
    _filteredSummaries = List<SummaryItem>.from(widget.summaries);
  }

  void _updateSummaries() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      _filteredSummaries = widget.summaries.where((item) {
        final matchesType = _selectedType == null || item.type == _selectedType;
        final matchesQuery = query.isEmpty ||
            item.title.toLowerCase().contains(query) ||
            item.summary.toLowerCase().contains(query) ||
            item.subtitle.toLowerCase().contains(query);
        return matchesType && matchesQuery;
      }).toList();
    });
  }

  Color _priorityColor(BuildContext context, PriorityLevel priority) {
    final scheme = Theme.of(context).colorScheme;
    switch (priority) {
      case PriorityLevel.urgent:
        return scheme.error;
      case PriorityLevel.high:
        return scheme.error;
      case PriorityLevel.medium:
        return scheme.secondary;
      case PriorityLevel.low:
        return scheme.tertiary;
    }
  }

  void _openSummaryDetail(SummaryItem item) {
    if (!mounted) return;

    if (item.type == SummaryType.call) {
      Navigator.pushNamed(context, '/call-detail', arguments: item);
    } else {
      Navigator.pushNamed(context, '/notification-detail', arguments: item);
    }
  }

  void _onTypeSelected(SummaryType? type) {
    _selectedType = type;
    _updateSummaries();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _updateSummaries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('All Summaries'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search summaries',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedType == null,
                      onSelected: (selected) {
                        if (selected) {
                          _onTypeSelected(null);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Calls'),
                      selected: _selectedType == SummaryType.call,
                      onSelected: (selected) =>
                          _onTypeSelected(selected ? SummaryType.call : null),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Notifications'),
                      selected: _selectedType == SummaryType.notification,
                      onSelected: (selected) => _onTypeSelected(
                          selected ? SummaryType.notification : null),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredSummaries.isEmpty
                  ? _EmptySummariesState(onRefresh: _updateSummaries)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredSummaries.length,
                      itemBuilder: (context, index) {
                        final summary = _filteredSummaries[index];
                        return SummaryCard(
                          title: summary.title,
                          summary: summary.summary,
                          subtitle: summary.subtitle,
                          leadingIcon: summary.type == SummaryType.call
                              ? Icons.phone
                              : Icons.notifications,
                          accentColor:
                              _priorityColor(context, summary.priority),
                          onTap: () => _openSummaryDetail(summary),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySummariesState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptySummariesState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 72, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No summaries yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Summaries from your recent calls and notifications will appear here once available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';

import '../../providers/library_providers.dart';

Future<void> showFileFilterSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final query = ref.watch(libraryQueryProvider);
          final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UdmSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: UdmSpacing.lg),
                    Text(
                      'Source',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: UdmSpacing.sm),
                    Wrap(
                      spacing: UdmSpacing.sm,
                      runSpacing: UdmSpacing.sm,
                      children: LibrarySourceFilterLabel.chipOrder
                          .map(
                            (filter) => FilterChip(
                              label: Text(filter.label),
                              selected: query.sourceFilter == filter,
                              onSelected: (_) {
                                ref.read(libraryQueryProvider.notifier).state =
                                    query.copyWith(sourceFilter: filter);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: UdmSpacing.lg),
                    Text('Size', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: UdmSpacing.sm),
                    Wrap(
                      spacing: UdmSpacing.sm,
                      runSpacing: UdmSpacing.sm,
                      children: LibrarySizeFilter.values
                          .map(
                            (filter) => FilterChip(
                              label: Text(filter.label),
                              selected: query.sizeFilter == filter,
                              onSelected: (_) {
                                ref.read(libraryQueryProvider.notifier).state =
                                    query.copyWith(sizeFilter: filter);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: UdmSpacing.lg),
                    Text(
                      'Modified',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: UdmSpacing.sm),
                    Wrap(
                      spacing: UdmSpacing.sm,
                      runSpacing: UdmSpacing.sm,
                      children: LibraryDateFilter.values
                          .map(
                            (filter) => FilterChip(
                              label: Text(filter.label),
                              selected: query.dateFilter == filter,
                              onSelected: (_) {
                                ref.read(libraryQueryProvider.notifier).state =
                                    query.copyWith(dateFilter: filter);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: UdmSpacing.lg),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(libraryQueryProvider.notifier).state =
                                query.copyWith(clearFilters: true);
                          },
                          child: const Text('Clear filters'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

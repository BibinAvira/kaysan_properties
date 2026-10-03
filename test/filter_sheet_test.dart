import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kaysan_properties/models/project_model.dart';
import 'package:kaysan_properties/providers/content_providers.dart';
import 'package:kaysan_properties/providers/search_provider.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import 'package:kaysan_properties/services/projects_service.dart';
import 'package:kaysan_properties/views/listings/widgets/filter_sheet.dart';

/// Opens the real [FilterSheet] the way Listings does (a modal bottom
/// sheet), with the area/developer directories stubbed so no network runs.
Future<ProviderContainer> openSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final ProviderContainer container = ProviderContainer(overrides: [
    allAreasProvider.overrideWith((Ref ref) async => const <AreaRef>[AreaRef(217, 'Dubai Marina')]),
    developersProvider.overrideWith((Ref ref) async => const <DeveloperModel>[DeveloperModel(id: 72, name: 'Emaar')]),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FilterSheet(),
              ),
              child: const Text('Open filters'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open filters'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('sort picker lists every sort and applies the one picked', (WidgetTester tester) async {
    for (final ProjectSort sort in ProjectSort.values) {
      final ProviderContainer c = await openSheet(tester);
      await tester.ensureVisible(find.text(c.read(projectFilterProvider).sort.label).last);
      await tester.tap(find.text(c.read(projectFilterProvider).sort.label).last);
      await tester.pumpAndSettle();
      // Every option is offered in the picker.
      for (final ProjectSort s in ProjectSort.values) {
        expect(find.text(s.label), findsWidgets, reason: s.label);
      }
      await tester.tap(find.text(sort.label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(c.read(projectFilterProvider).sort, sort, reason: sort.label);
    }
  });

  testWidgets('handover From/To date pickers set the range; Clear and Reset remove it', (WidgetTester tester) async {
    final ProviderContainer c = await openSheet(tester);
    final DateTime now = DateTime.now();
    final int nextYear = now.year + 1;
    String month(DateTime d) => DateFormat('MMM yyyy').format(d);

    // From: open the picker (year view), choose next year, confirm.
    await tester.ensureVisible(find.text('From'));
    await tester.tap(find.text('From'));
    await tester.pumpAndSettle();
    expect(find.text('Handover from'), findsOneWidget);
    await tester.tap(find.text('$nextYear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final DateTime from = DateTime(nextYear, now.month, now.day);
    expect(find.text(month(from)), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // To: the picker can't go earlier than From; confirm its default.
    await tester.tap(find.text('To'));
    await tester.pumpAndSettle();
    expect(find.text('Handover until'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(month(from)), findsNWidgets(2));

    // Nothing is applied until Search.
    expect(c.read(projectFilterProvider).hasHandoverFilter, isFalse);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    final ProjectFilter applied = c.read(projectFilterProvider);
    expect(applied.handoverFrom, from);
    expect(applied.handoverTo, isNotNull);
    expect(applied.handoverTo!.isBefore(applied.handoverFrom!), isFalse);

    // Reopened, the sheet shows the applied range; Clear empties it.
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    expect(find.text(month(from)), findsNWidgets(2));
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(c.read(projectFilterProvider).hasHandoverFilter, isFalse);

    // Reset (top right) clears an applied range immediately.
    c.read(projectFilterProvider.notifier).setHandoverRange(DateTime(2027), DateTime(2028));
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(c.read(projectFilterProvider).hasHandoverFilter, isFalse);
  });

  testWidgets('To picker cannot go before From', (WidgetTester tester) async {
    final ProviderContainer c = await openSheet(tester);
    c.read(projectFilterProvider.notifier).setHandoverRange(DateTime(2028, 6, 1), null);
    // Reopen so the sheet starts from the applied range.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('To'));
    await tester.tap(find.text('To'));
    await tester.pumpAndSettle();
    // The picker opens on (at least) From's month — earlier years are disabled.
    final CalendarDatePicker picker = tester.widget(find.byType(CalendarDatePicker));
    expect(picker.firstDate, DateTime(2028, 6, 1));
    expect(picker.initialDate!.isBefore(DateTime(2028, 6, 1)), isFalse);
  });
}

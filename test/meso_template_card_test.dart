import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/template_data.dart';
import 'package:workout_of_record/widgets/meso_template_card.dart';

void main() {
  MesoTemplateWithHistory history({
    required int id,
    required String name,
    required DateTime created,
    DateTime? lastUsed,
  }) {
    return MesoTemplateWithHistory(
      template: MesoTemplate(id: id, name: name, createdAt: created),
      pastMesos: lastUsed == null
          ? const []
          : [
              Mesocycle(
                id: id,
                mesoTemplateId: id,
                name: name,
                totalWeekCount: 4,
                createdAt: lastUsed,
              ),
            ],
    );
  }

  test('template sort supports name, creation date, and last-used date', () {
    final alpha = history(
      id: 1,
      name: 'Alpha',
      created: DateTime(2025),
      lastUsed: DateTime(2026, 1),
    );
    final beta = history(
      id: 2,
      name: 'Beta',
      created: DateTime(2026),
      lastUsed: DateTime(2025, 1),
    );
    final neverUsed = history(id: 3, name: 'Never', created: DateTime(2024));
    final templates = [beta, neverUsed, alpha];

    expect(
      sortMesoTemplates(
        templates,
        MesoTemplateSort.name,
      ).map((item) => item.template.name),
      ['Alpha', 'Beta', 'Never'],
    );
    expect(
      sortMesoTemplates(
        templates,
        MesoTemplateSort.created,
      ).map((item) => item.template.name),
      ['Beta', 'Alpha', 'Never'],
    );
    expect(
      sortMesoTemplates(
        templates,
        MesoTemplateSort.lastUsed,
      ).map((item) => item.template.name),
      ['Alpha', 'Beta', 'Never'],
    );
  });
}

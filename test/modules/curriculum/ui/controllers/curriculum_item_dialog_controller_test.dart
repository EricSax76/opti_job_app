import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/controllers/curriculum_item_dialog_controller.dart';

void main() {
  test('uses add title when initial item is null', () {
    final controller = CurriculumItemDialogController();
    addTearDown(controller.dispose);

    expect(controller.title, 'Agregar');
  });

  test('buildResult trims form fields', () {
    final controller = CurriculumItemDialogController(
      initial: const CurriculumItem(
        title: ' Initial ',
        subtitle: ' Sub ',
        period: ' 2020 ',
        description: ' Desc ',
      ),
    );
    addTearDown(controller.dispose);

    controller.titleController.text = '  Dev Senior ';
    controller.subtitleController.text = '  Empresa X  ';
    controller.periodController.text = '  2020 - 2024  ';
    controller.descriptionController.text = '  Logros clave  ';

    final item = controller.buildResult();

    expect(controller.title, 'Editar');
    expect(
      item,
      const CurriculumItem(
        title: 'Dev Senior',
        subtitle: 'Empresa X',
        period: '2020 - 2024',
        description: 'Logros clave',
      ),
    );
  });
}

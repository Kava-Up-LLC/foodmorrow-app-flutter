import '../../core/appambit/analytics.dart';
import '../../core/loadable.dart';
import 'data/product.dart';
import 'menu_repository.dart';

/// New item / Edit item. The only screen that writes to the menu.
class ItemFormController extends LoadableController {
  ItemFormController({required this.repository, required this.analytics, this.editing}) {
    if (editing != null) {
      name = editing!.name;
      photo = editing!.photo;
    }
  }

  static const maxName = 40;

  final MenuRepository repository;
  final Analytics analytics;

  /// The item being changed, or null when this is a new one.
  final Product? editing;

  String name = '';
  String? photo;

  bool get isEditing => editing != null;

  /// Nothing to load: the menu came with the screen that opened this one.
  @override
  Future<void> fetch() async {}

  String get trimmedName => name.trim();

  bool get isValid => trimmedName.isNotEmpty && trimmedName.length <= maxName;

  /// "Add to menu" for a new item, "Save" when editing.
  String get buttonLabel => isEditing ? 'Save' : 'Add to menu';

  String get title => isEditing ? 'Edit item' : 'New item';

  void setName(String value) {
    name = value;
    clearFailure();
    refresh();
  }

  /// Tapping one of the four circles: the selected one again means "no photo".
  void setPhoto(String? key) {
    photo = photo == key ? null : key;
    refresh();
  }

  /// Picked from the "More photos" sheet: always that one.
  void choosePhoto(String key) {
    photo = key;
    refresh();
  }

  /// Saves and reports whether it went through.
  Future<bool> save() => runWrite(() async {
        if (isEditing) {
          await repository.edit(id: editing!.id, name: trimmedName, photo: photo);
        } else {
          await repository.add(name: trimmedName, photo: photo);
          analytics.track(Events.productAdded, {'has_photo': '${photo != null}'});
        }
      });

  Future<bool> remove() => runWrite(() async {
        await repository.remove(editing!.id);
      });
}

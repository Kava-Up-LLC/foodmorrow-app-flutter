/// The built-in photo library (spec §2 rule 10). A product stores the key, never a path, so moving
/// the files or adding more never touches the orders already saved.
///
/// To grow the library: add the JPG to `assets/food/`, its key here, and its line in
/// `assets/food/CREDITS.md`.
abstract final class FoodPhotos {
  /// Every key, in the order the picker shows them. The first four are the ones on the item screen.
  static const keys = <String>['cookies', 'chocolate_cake', 'lasagna', 'brownies'];

  /// The four shown without opening "More photos".
  static List<String> get firstFour => keys.take(4).toList();

  static String pathOf(String key) => 'assets/food/$key.jpg';

  static bool has(String? key) => key != null && keys.contains(key);

  /// The asset for a key, or null when there is no photo (or the key is from a newer version of the
  /// app than this one — the item simply shows the dashed circle).
  static String? assetOf(String? key) => has(key) ? pathOf(key!) : null;
}

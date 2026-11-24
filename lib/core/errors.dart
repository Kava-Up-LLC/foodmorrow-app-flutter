/// What can go wrong, in the words the screens need.
enum FailureKind { noConnection, badInput, duplicate, notFound, unexpected }

class AppFailure implements Exception {
  const AppFailure(this.kind, [this.cause]);

  /// Maps the `error` a Cloud Code function answers with.
  factory AppFailure.fromCode(String? code) => switch (code) {
        'BAD_INPUT' => const AppFailure(FailureKind.badInput),
        'DUPLICATE' => const AppFailure(FailureKind.duplicate),
        'NOT_FOUND' => const AppFailure(FailureKind.notFound),
        _ => AppFailure(FailureKind.unexpected, code),
      };

  final FailureKind kind;
  final Object? cause;

  bool get isNoConnection => kind == FailureKind.noConnection;

  /// The title of the alert banner.
  String get title => switch (kind) {
        FailureKind.noConnection => 'No connection',
        FailureKind.duplicate => 'Already on your menu',
        FailureKind.notFound => 'Not there any more',
        FailureKind.badInput => 'Check what you typed',
        FailureKind.unexpected => 'Something went wrong',
      };

  /// The line under the title.
  String get message => switch (kind) {
        FailureKind.noConnection => 'Your orders are saved.',
        FailureKind.duplicate => 'You already have an item with that name.',
        FailureKind.notFound => 'Someone removed it, or it was never saved.',
        FailureKind.badInput => 'Some of it was not saved.',
        FailureKind.unexpected => 'Try again in a moment.',
      };

  @override
  String toString() => 'AppFailure($kind, $cause)';
}

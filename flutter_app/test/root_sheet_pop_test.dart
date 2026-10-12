import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Une feuille ouverte sur le navigateur racine se ferme avec SON context.
///
/// Depuis la 1.1.19, les feuilles s'ouvrent au-dessus de la barre d'onglets
/// (`useRootNavigator: true`), mais les écrans restent sur le navigateur de
/// leur onglet. `Navigator.pop(context)` avec le context de l'ÉCRAN ferme
/// alors l'écran, pas la feuille.
///
/// C'est arrivé à la photo de profil : « Prendre une photo » fermait l'écran
/// Modifier le profil, la caméra s'ouvrait quand même, et la photo revenait
/// vers un écran disparu — jamais envoyée. Les envois sont tombés de 665 à 6
/// par jour en une semaine (07/10/2026), sans une erreur nulle part.
///
/// Un test qui lit le code source, parce que le défaut ne se voit ni à la
/// compilation ni en relecture : seulement sur un téléphone, au bon écran.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// L'appel `show…(…)` qui contient [at], parenthèses équilibrées.
  String callAround(String src, int at) {
    final start = src.lastIndexOf(RegExp(r'show\w*\s*(<[^>]*>)?\s*\('), at);
    var i = src.indexOf('(', start);
    var depth = 0;
    for (var j = i; j < src.length; j++) {
      if (src[j] == '(') depth++;
      if (src[j] == ')' && --depth == 0) return src.substring(start, j + 1);
    }
    return src.substring(start);
  }

  final sheets = <({String where, String call, String builderParam})>[];
  for (final file in dartFiles) {
    final src = file.readAsStringSync();
    for (final m in RegExp(r'useRootNavigator:\s*true').allMatches(src)) {
      final call = callAround(src, m.start);
      final param =
          RegExp(r'builder:\s*\((\w+)').firstMatch(call)?.group(1) ?? '_';
      final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
      sheets
          .add((where: '${file.path}:$line', call: call, builderParam: param));
    }
  }

  test('il y a bien des feuilles sur le navigateur racine à vérifier', () {
    expect(sheets, isNotEmpty);
  });

  test('aucune feuille racine ne se ferme avec le context de l\'écran', () {
    final offenders = [
      for (final s in sheets)
        if (s.builderParam != 'context' &&
            RegExp(r'Navigator\.(pop|of)\(\s*context\b').hasMatch(s.call))
          s.where,
    ];

    expect(offenders, isEmpty,
        reason: 'Fermer avec le context du builder de la feuille '
            '(ex. `Navigator.pop(sheetContext)`), pas celui de l\'écran.');
  });

  test(
      'aucun bouton de feuille racine ne branche directement une méthode de '
      'l\'écran', () {
    // `onTap: _pickAvatar` : la méthode de l'écran fermait la feuille avec son
    // propre context. La feuille renvoie plutôt un choix, et l'écran agit une
    // fois qu'elle est fermée.
    final offenders = [
      for (final s in sheets)
        if (RegExp(r'on(Tap|Pressed):\s*_\w+\s*[,)]').hasMatch(s.call)) s.where,
    ];

    expect(offenders, isEmpty);
  });
}

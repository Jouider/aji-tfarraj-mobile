import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:aji_tfarraj/features/staff/domain/return_manifest.dart';

/// Turns the shuttle sheet into something that can leave the phone.
///
/// Two formats on purpose: a PDF for the record and for the driver to tick
/// names off, and a plain-text summary because what actually reaches the
/// transport lead at 23h is a WhatsApp message.
class ReturnManifestExport {
  ReturnManifestExport._();

  static final _dateTime = DateFormat('dd/MM/yyyy · HH:mm');
  static final _date = DateFormat('dd/MM/yyyy');
  static final _time = DateFormat('HH:mm');
  static final _fileStamp = DateFormat('yyyy-MM-dd');
  static final _fileTime = DateFormat("HH'h'mm");

  /// Arabic only joins its letters and reorders when the run is marked RTL, so
  /// every string gets the direction its own script needs. Stop names and
  /// attendee names come from a bilingual database — forcing one direction on
  /// the whole document would mangle half of them.
  static final _arabic = RegExp(
      '[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');

  static pw.TextDirection _direction(String value) =>
      _arabic.hasMatch(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// The page is laid out left-to-right whatever the script: a driver reading
  /// down the checklist needs every name to start in the same column. Only the
  /// *inside* of an Arabic run is right-to-left, which is what [_direction]
  /// gives it.
  static pw.Widget _text(
    String value, {
    pw.TextStyle? style,
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Text(
        value,
        style: style,
        textAlign: align,
        textDirection: _direction(value),
      );

  // ── PDF ───────────────────────────────────────────────────────────────────

  /// The sheet as PDF bytes. Kept free of the filesystem so it can be built
  /// and checked without a platform channel.
  static Future<Uint8List> pdfBytes(ReturnManifest manifest) async {
    // The built-in PDF fonts carry no Arabic glyphs at all, so an Arabic name
    // would come out as blanks. Cairo is the app's Arabic face already.
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: 'Feuille de retour',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        header: (context) =>
            context.pageNumber == 1 ? _header(manifest) : pw.SizedBox(),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Aji Tfarraj · page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _totals(manifest),
          pw.SizedBox(height: 18),
          if (manifest.hasOrphanedPassengers) ...[
            _warning(
              "Un arrêt a été retiré de ce tournage après que des personnes "
              "l'aient choisi. Elles attendent quand même : voir les lignes "
              "marquées « hors liste ».",
            ),
            pw.SizedBox(height: 14),
          ],
          _pointsTable(manifest),
          pw.SizedBox(height: 22),
          ..._passengerLists(manifest),
        ],
      ),
    );

    return doc.save();
  }

  /// The sheet as a file on disk, ready to hand to the share sheet.
  static Future<File> writePdf(ReturnManifest manifest) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${fileName(manifest)}');
    await file.writeAsBytes(await pdfBytes(manifest));

    return file;
  }

  /// Named for the recording, then for the moment it was drawn up. Several
  /// scanners each send their own copy, and two attachments with the same name
  /// and different numbers is how the wrong one gets acted on.
  static String fileName(ReturnManifest manifest) {
    final day = _fileStamp.format(manifest.episode.startsAt ?? manifest.generatedAt);
    return 'retour-navette_${day}_${_fileTime.format(manifest.generatedAt)}.pdf';
  }

  static pw.Widget _header(ReturnManifest manifest) {
    final episode = manifest.episode;
    final subtitle = [
      if (manifest.showTitle.isNotEmpty) manifest.showTitle,
      if (episode.title != null && episode.title!.isNotEmpty) episode.title!,
    ].join(' — ');

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Feuille de retour — navette',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  _text(subtitle, style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 2),
                _text(
                  [
                    if (episode.startsAt != null) _dateTime.format(episode.startsAt!),
                    if (episode.studio != null && episode.studio!.isNotEmpty) episode.studio!,
                    if (episode.city != null && episode.city!.isNotEmpty) episode.city!,
                  ].join(' · '),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.Text(
            'Établie le\n${_dateTime.format(manifest.generatedAt)}',
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totals(ReturnManifest manifest) {
    pw.Widget box(String label, int value, PdfColor colour) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const pw.EdgeInsets.only(right: 8),
            decoration: pw.BoxDecoration(
              color: colour,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$value',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
              ],
            ),
          ),
        );

    return pw.Row(children: [
      box('personnes entrées', manifest.checkedInPeople, PdfColors.grey200),
      box('attendent la navette', manifest.riders, PdfColors.amber100),
      box('repartent seules', manifest.ownMeans, PdfColors.grey100),
    ]);
  }

  static pw.Widget _warning(String message) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.red50,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.red200),
        ),
        child: pw.Text(message,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
      );

  static pw.Widget _pointsTable(ReturnManifest manifest) {
    pw.Widget cell(pw.Widget child, {pw.Alignment align = pw.Alignment.centerLeft}) =>
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          alignment: align,
          child: child,
        );

    pw.Widget head(String label, {pw.Alignment align = pw.Alignment.centerLeft}) => cell(
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800)),
          align: align,
        );

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      // No ticket-count column: a booking is capped at one seat, so it would
      // repeat the headcount in a narrower font.
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(75),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            head('Arrêt'),
            head('Repère'),
            head('Personnes', align: pw.Alignment.centerRight),
          ],
        ),
        for (final point in manifest.points)
          pw.TableRow(children: [
            cell(pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _text(point.name,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: point.isEmpty
                            ? pw.FontWeight.normal
                            : pw.FontWeight.bold,
                        color: point.isEmpty ? PdfColors.grey600 : PdfColors.black)),
                if (!point.served)
                  pw.Text('hors liste de ce tournage',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.red700)),
              ],
            )),
            cell(_text(point.landmark ?? '—',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
            cell(
              pw.Text('${point.people}',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: point.isEmpty ? PdfColors.grey500 : PdfColors.black)),
              align: pw.Alignment.centerRight,
            ),
          ]),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            cell(pw.Text('Total navette',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            cell(pw.SizedBox()),
            cell(
              pw.Text('${manifest.riders}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
      ],
    );
  }

  /// Names per stop, so the driver can call them at the door of the vehicle.
  ///
  /// Two columns: a busy stop runs to twenty-odd people, and one name per line
  /// down an A4 page would have the driver flipping pages at the kerb.
  static List<pw.Widget> _passengerLists(ReturnManifest manifest) {
    final withPeople = manifest.servedTonight;
    if (withPeople.isEmpty) return [];

    return [
      pw.Text('Passagers par arrêt',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      for (final point in withPeople) _pointBlock(point),
    ];
  }

  /// A stop's heading stays with its names.
  ///
  /// Only up to [_keepTogetherLimit] though: MultiPage *throws* on an
  /// inseparable block taller than a page, and crashing in the scanner's hands
  /// at the end of a recording is far worse than a heading left at a page
  /// bottom. Beyond that the block spans, as it did before.
  static const _keepTogetherLimit = 24;

  static pw.Widget _pointBlock(ManifestPoint point) {
    final block = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Expanded(
              child: _text(point.name,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('${point.people} pers.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ]),
          pw.Divider(height: 8, color: PdfColors.grey300),
          _passengerGrid(point.passengers),
        ],
      ),
    );

    return point.passengers.length <= _keepTogetherLimit
        ? pw.Inseparable(child: block)
        : block;
  }

  /// Two per row, filled left to right. A Table rather than a Wrap so the two
  /// columns line up and the rows break cleanly across pages.
  static pw.Widget _passengerGrid(List<ManifestPassenger> passengers) {
    const columns = 2;
    final rows = <pw.TableRow>[];

    for (var i = 0; i < passengers.length; i += columns) {
      rows.add(pw.TableRow(
        children: [
          for (var column = 0; column < columns; column++)
            i + column < passengers.length
                ? _passengerCell(passengers[i + column])
                : pw.SizedBox(),
        ],
      ));
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  static pw.Widget _passengerCell(ManifestPassenger passenger) => pw.Padding(
        padding: const pw.EdgeInsets.only(right: 12, top: 3, bottom: 3),
        child: pw.Row(children: [
          // An empty box in front of each name: the driver ticks people off on
          // paper as they board.
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(right: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.6),
            ),
          ),
          pw.Expanded(
            child: _text(passenger.name, style: const pw.TextStyle(fontSize: 9)),
          ),
          // Never happens while a booking is capped at one seat, but a legacy
          // multi-seat row must not be under-reported to the driver.
          if (passenger.seats > 1)
            pw.Text('×${passenger.seats}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  // ── Plain text ────────────────────────────────────────────────────────────

  /// The WhatsApp version. What actually reaches the transport lead at 23h is a
  /// message, not an attachment — and plain text carries Arabic without any of
  /// the font trouble a PDF has.
  static String buildText(ReturnManifest manifest) {
    final episode = manifest.episode;
    final lines = <String>[
      '🚐 Retour navette',
      [
        if (manifest.showTitle.isNotEmpty) manifest.showTitle,
        if (episode.title != null && episode.title!.isNotEmpty) episode.title!,
      ].join(' — '),
      if (episode.startsAt != null)
        '${_date.format(episode.startsAt!)}'
            '${episode.studio != null && episode.studio!.isNotEmpty ? ' · ${episode.studio}' : ''}',
      // With several scanners at the door, more than one of these messages
      // reaches the transport lead. Without a time they cannot tell which one
      // is the later count.
      'Arrêté à ${_time.format(manifest.generatedAt)}',
      '',
    ];

    if (manifest.servedTonight.isEmpty) {
      lines.add('Personne n\'attend la navette.');
    } else {
      for (final point in manifest.servedTonight) {
        final flag = point.served ? '' : ' ⚠️ hors liste';
        lines.add('• ${point.name} : ${point.people} pers.$flag');
      }
    }

    lines
      ..add('')
      ..add('Total navette : ${manifest.riders} pers.')
      ..add('Repartent seules : ${manifest.ownMeans} pers.')
      ..add('Entrées ce soir : ${manifest.checkedInPeople} pers.');

    return lines.join('\n');
  }
}

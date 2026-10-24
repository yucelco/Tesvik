import 'package:intl/intl.dart';

import '../model/ortak.dart';

const _semboller = {ParaBirimi.TRY: '₺', ParaBirimi.USD: r'$', ParaBirimi.EUR: '€'};

String para(double deger, ParaBirimi birim) =>
    NumberFormat.currency(locale: 'tr_TR', symbol: _semboller[birim], decimalDigits: 0).format(deger);

String yuzde(double oran) => '%${(oran * 100).round()}';

String sayi(num deger) => NumberFormat.decimalPattern('tr_TR').format(deger);

String tarih(DateTime t) => DateFormat('d MMMM y', 'tr_TR').format(t);

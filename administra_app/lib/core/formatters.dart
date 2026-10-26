String texto(dynamic valor) {
  if (valor == null) {
    return '-';
  }

  final texto = valor.toString().trim();

  if (texto.isEmpty) {
    return '-';
  }

  return texto;
}

String formatarValor(dynamic valor) {
  final numero = double.tryParse(valor.toString()) ?? 0;
  return 'R\$ ${numero.toStringAsFixed(2)}';
}

String formatarData(dynamic valor) {
  if (valor == null) {
    return '-';
  }

  return valor.toString().replaceAll('T', ' ');
}

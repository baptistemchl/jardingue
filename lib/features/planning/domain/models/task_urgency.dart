import 'package:flutter/material.dart';

enum TaskUrgency {
  now('Maintenant', Color(0xFFE53935)),
  soon('Cette semaine', Color(0xFFFFA726)),
  upcoming('Ce mois', Color(0xFF42A5F5)),
  blocked('Bloqué', Color(0xFF9E9E9E)),
  waiting('Pas encore', Color(0xFFBDBDBD));

  final String label;
  final Color color;

  const TaskUrgency(this.label, this.color);
}

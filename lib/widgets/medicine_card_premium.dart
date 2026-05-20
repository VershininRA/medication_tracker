import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineCardPremium extends StatefulWidget {
  final Medicine medicine;
  final bool isTaken;
  final VoidCallback onTake;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCardPremium({
    Key? key,
    required this.medicine,
    required this.isTaken,
    required this.onTake,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<MedicineCardPremium> createState() => _MedicineCardPremiumState();
}

class _MedicineCardPremiumState extends State<MedicineCardPremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8A4B8).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👉 Верхняя строка: Название + Чекбокс
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Чекбокс
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: widget.isTaken,
                            onChanged: (val) {
                              if (val == true) {
                                widget.onTake();
                              }
                            },
                            activeColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Название и дозировка
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.medicine.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF2D2428),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (widget.medicine.dosage != null &&
                                  widget.medicine.dosage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFE8A4B8).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.medicine.dosage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFE8A4B8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Статус
                        if (widget.isTaken)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Color(0xFF4CAF50),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Принято',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 👉 Расписание
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFFE8A4B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.medicine.schedule.join(' • '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.medicine.description != null &&
                        widget.medicine.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.medicine.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 👉 Кнопки действий
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text(
                              'Редактировать',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              foregroundColor: const Color(0xFFE8A4B8),
                              side: const BorderSide(
                                color: Color(0xFFE8A4B8),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(''),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

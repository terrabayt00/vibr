import 'package:flutter/material.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/model/control_model.dart';
import 'package:magic_control/screens/control/components/custom_label.dart';
import 'package:magic_control/screens/control/components/gear_grid_view.dart';

class ButtonGrid extends StatefulWidget {
  const ButtonGrid({super.key, required this.model, required this.sessionId});
  final ControlModel model;
  final String sessionId;

  @override
  State<ButtonGrid> createState() => _ButtonGridState();
}

class _ButtonGridState extends State<ButtonGrid> {
  final DbHelper _db = DbHelper();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Додаємо StreamBuilder для прогресу
        StreamBuilder(
          stream: _db.fetchProgressData(widget.sessionId),
          builder: (context, progressSnapshot) {
            if (progressSnapshot.hasData && progressSnapshot.data != null) {
              final progressData = progressSnapshot.data!;
              final percentage = double.tryParse(progressData['percentage'] ?? '0') ?? 0;
              final isUploading = progressData['is_uploading'] ?? false;
              final currentFileName = progressData['current_file_name'] ?? '';
              final currentFile = progressData['current_file'] ?? 0;
              final totalFiles = progressData['total_files'] ?? 0;

              // Визначаємо колір іконки залежно від прогресу
              Color progressColor;
              IconData progressIcon;
              String statusText;

              if (percentage >= 100) {
                progressColor = Colors.green;
                progressIcon = Icons.check_circle;
                statusText = 'Завершено';
              } else if (isUploading) {
                progressColor = Colors.blue;
                progressIcon = Icons.upload;
                statusText = 'Завантаження...';
              } else {
                progressColor = Colors.orange;
                progressIcon = Icons.pause_circle;
                statusText = 'На паузі';
              }

              return Container(
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Заголовок
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              progressIcon,
                              color: progressColor,
                              size: 20.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Статус завантаження',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: progressColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.0),

                    // Прогрес бар
                    Stack(
                      children: [
                        LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 16.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: percentage > 50 ? Colors.white : Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.0),

                    // Деталі
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Файл:',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              currentFileName.isEmpty ? 'Немає активних файлів' : currentFileName,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Прогрес:',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              '$currentFile / $totalFiles',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (percentage >= 100)
                      SizedBox(height: 8.0),

                    if (percentage >= 100)
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'Всі файли успішно завантажено',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),

        // Основний контент
        Expanded(
          child: _buildControl(),
        ),
      ],
    );
  }

  Widget _buildControl() {
    ControlModel model = widget.model;
    return SingleChildScrollView(
      child: Column(
        children: [
          const CustomLabel(text: 'Общие'),
          GearGridView(
            items: vibratorGlobal,
            cat: 'Общие',
            selectedCard: model.global,
          ),
          const CustomLabel(text: 'Режимы вибрации'),
          GearGridView(
            items: vibratorModes,
            cat: 'Режимы вибрации',
            selectedCard: model.modes,
          ),
          const CustomLabel(text: 'Интенсивность вибрации'),
          GearGridView(
            items: vibratorIntensive,
            cat: 'Интенсивность вибрации',
            selectedCard: model.intensive,
          ),
          const CustomLabel(text: 'Другие'),
          GearGridView(
            items: vibratorOther,
            cat: 'Другие',
            selectedCard: model.other,
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
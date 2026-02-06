import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import '../models/exam_models.dart';
import '../screens/exam_runner_page.dart';

class ExamConfigurationDialog extends StatefulWidget {
  final String examType; // Artık sadece başlık/log için

  const ExamConfigurationDialog({
    super.key, 
    required this.examType,
  });

  @override
  State<ExamConfigurationDialog> createState() => _ExamConfigurationDialogState();
}

class _ExamConfigurationDialogState extends State<ExamConfigurationDialog> {
  String _selectedCategory = 'grammar';
  int _questionCount = 10;
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'grammar', 'label': 'Grammar', 'icon': '📝'},
    {'value': 'vocabulary', 'label': 'Vocabulary', 'icon': '📚'},
    {'value': 'sentence_completion', 'label': 'Cümle Tamamlama', 'icon': '✏️'},
    {'value': 'translation', 'label': 'Çeviri (İng-Tr)', 'icon': '🔄'},
    {'value': 'paragraph_completion', 'label': 'Paragraf Tamamlama', 'icon': '📄'},
    {'value': 'reading', 'label': 'Okuma Parçası', 'icon': '📖'},
    {'value': 'cloze_test', 'label': 'Cloze Test', 'icon': '🧩'},
  ];

  Future<void> _startExam() async {
    setState(() => _isLoading = true);

    try {
      final ExamBundle exam = await GroqService.generateExamBundle(
        examType: "YDS/YÖKDİL", 
        // mode parametresi artık GroqService içinde yok sayılabilir veya 'category' gönderilir
        mode: "category",
        category: _selectedCategory,
        questionCount: _questionCount,
        // track parametresi kaldırıldı (Genel)
        userLevel: "C1",
      );

      if (!mounted) return;
      Navigator.pop(context); // Dialogu kapat
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamRunnerPage(examBundle: exam),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366f1);
    const bgColor = Color(0xFF0f172a);
    const surfaceColor = Color(0xFF1e293b);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: primaryColor),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YDS / YÖKDİL Çalışma',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Konu Bazlı Test Oluştur',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KATEGORİ SEÇİMİ
            const Text('Kategori Seçin', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: surfaceColor,
                  icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Row(
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Text(cat['label']!, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SORU SAYISI
            const Text('Soru Sayısı', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Ortala
              children: [5, 10].map((count) {
                final isSelected = _questionCount == count;
                return Container(
                  width: 80, // Sabit genişlik ile daha düzgün görünüm
                  margin: const EdgeInsets.symmetric(horizontal: 12), // Aralarına boşluk
                  child: GestureDetector(
                    onTap: () => setState(() => _questionCount = count),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.white10,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // START BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Testi Başlat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

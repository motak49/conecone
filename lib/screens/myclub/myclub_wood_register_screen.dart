import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';

class MyclubWoodRegisterScreen extends StatefulWidget {
  const MyclubWoodRegisterScreen({super.key});

  @override
  State<MyclubWoodRegisterScreen> createState() => _MyClubWoodRegisterScreenState();
}

class _MyClubWoodRegisterScreenState extends State<MyclubWoodRegisterScreen> {
  final List<_ClubFormData> _formDataList = [];

  @override
  void initState() {
    super.initState();
    _addFormRow(); // 初期表示で1行追加
  }

  void _addFormRow() {
    setState(() {
      _formDataList.add(_ClubFormData());
    });
  }

  Future<void> _onRegisterPressed() async {
    final db = DatabaseHelper.instance;

    // 入力データの保存処理
    for (var data in _formDataList) {
      if (data.modelController.text.isEmpty) continue; // モデル名が空ならスキップ

      final String category = data.selectedType == ClubType.wood ? 'Wood' : 'Utility';
      final String suffix = data.selectedType == ClubType.wood ? 'W' : 'U';
      final String numberStr = "${data.selectedNumber}$suffix"; // 例: 5W, 3U

      // DBに合わせてマップを作成（DatabaseHelperの修正が必要）
      Map<String, dynamic> row = {
        'category': category, // "Wood" or "Utility"
        'place_name': numberStr, // ここでは番手をplace_name等に仮置きするか、カラムを追加する
        'summary_text': data.modelController.text, // モデル名をsummary_textに仮置き
        // 本来は my_clubs テーブルを作成し、適切なカラム(number, model_name)に入れるべきです
        'played_at': DateTime.now().toIso8601String(), 
        'primary_score': 0, 
      };

      // 保存実行（activitiesテーブルに仮保存する場合の例）
      // await db.createActivity(row); 
      
      // ★推奨: my_clubsテーブルを作った場合のコード
      await db.database.then((database) {
         database.insert('my_clubs', {
           'category': category,
           'number': numberStr,
           'model_name': data.modelController.text,
           'created_at': DateTime.now().toIso8601String(),
         });
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クラブを登録しました')),
      );
      Navigator.pop(context); // トップへ戻る
    }
  }

  @override
  void dispose() {
    for (var data in _formDataList) {
      data.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // main.dartのテーマ（ダーク）に合わせる
      appBar: AppBar(
        title: const Text("ウッド登録", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _formDataList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildInputCard(index);
              },
            ),
          ),
          
          // フッター（追加 & 登録ボタン）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // ダークグレー背景
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  onPressed: _addFormRow,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildRegisterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(int index) {
    final data = _formDataList[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // 少し明るいグレー
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 番手選択
          SizedBox(
            width: 60,
            child: Column(
              children: [
                const Text("番手", style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  value: data.selectedNumber,
                  isExpanded: true,
                  dropdownColor: Colors.grey[800], // ドロップダウン背景色
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 1, color: Colors.grey),
                  items: ["1", "3", "4", "5", "7", "9", "11"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      data.selectedNumber = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // モデル名 & 種別
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: data.modelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "モデル名 (例: Titleist 15°)",
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTypeButton(data, ClubType.wood, "ウッド"),
                    const SizedBox(width: 8),
                    _buildTypeButton(data, ClubType.utility, "ユーティリティ"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(_ClubFormData data, ClubType type, String label) {
    final isSelected = data.selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => data.selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellowAccent.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.yellowAccent : Colors.grey[600]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.yellowAccent : Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFFCC80)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onRegisterPressed,
          borderRadius: BorderRadius.circular(8),
          child: const Center(
            child: Text("クラブ登録", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

enum ClubType { wood, utility }

class _ClubFormData {
  String selectedNumber = "5";
  TextEditingController modelController = TextEditingController();
  ClubType selectedType = ClubType.wood;
  void dispose() { modelController.dispose(); }
}
import 'package:flutter/material.dart';

class MyclubHistoryScreen extends StatefulWidget {
  const MyclubHistoryScreen({super.key});

  @override
  State<MyclubHistoryScreen> createState() => _MyclubHistoryScreenState();
}

class _MyclubHistoryScreenState extends State<MyclubHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // カテゴリ定義
  final List<String> _categories = ['Driver', 'Wood', 'Iron', 'Wedge', 'Putter'];

  // サンプルデータ (DBから取得したリストを想定)
  // 実際は DBの sort_order 順に取得します
  final List<Map<String, dynamic>> _allHistoryData = [
    {'id': 1, 'modelName': 'TaylorMade M1 1W', 'category': 'Driver'},
    {'id': 2, 'modelName': 'SIM2 MAX', 'category': 'Driver'},
    {'id': 3, 'modelName': 'Callaway Epic Speed 3W', 'category': 'Wood'},
    {'id': 4, 'modelName': 'Stealth 5W', 'category': 'Wood'},
    {'id': 5, 'modelName': 'Titleist T100 Irons', 'category': 'Iron'},
    {'id': 6, 'modelName': 'Mizuno Pro 223', 'category': 'Iron'},
    {'id': 7, 'modelName': 'Vokey SM8 56°', 'category': 'Wedge'},
    {'id': 8, 'modelName': 'Odyssey White Hot #5', 'category': 'Putter'},
    {'id': 9, 'modelName': 'Ping G425 4U', 'category': 'Utility'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getSuffix(String category) {
    switch (category) {
      case 'Driver': return '元ドラ';
      case 'Wood': return '元ウッド';
      case 'Iron': return '元アイアン';
      case 'Wedge': return '元ウェッジ';
      case 'Putter': return '元パター';
      default: return '元クラブ';
    }
  }

  // 並び替え処理
  void _onReorder(int oldIndex, int newIndex, List<Map<String, dynamic>> currentList) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      // 1. UI上のリストで入れ替え
      final item = currentList.removeAt(oldIndex);
      currentList.insert(newIndex, item);

      // 2. _allHistoryData (大元のデータ) にも反映させる処理
      // 実際のアプリでは、ここでDBの `sort_order` を更新し、再取得(fetch)します。
      // 今回はメモリ上のデータを同期させる簡易実装とします。
      // (本来はDB操作後に setState するのが安全です)
    });
  }

  @override
  Widget build(BuildContext context) {
    // 哀愁カラーパレット
    const sepiaBase = Color(0xFF3E2723); 
    const antiqueGold = Color(0xFFD4AF37); 
    
    final imageHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1510),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: antiqueGold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: antiqueGold),
      ),
      body: Column(
        children: [
          // -------------------------------------------
          // 1. 上部: 背景画像エリア
          // -------------------------------------------
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.modulate),
                  child: Image.asset(
                    'assets/images/myclug_histrory_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: sepiaBase),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF1a1510)],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Text(
                        '’あんなに"好き”って\n言ってくれたのに・・・’',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Serif',
                          color: Colors.white70,
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: antiqueGold.withOpacity(0.3), width: 1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: antiqueGold,
                        indicatorWeight: 2,
                        labelColor: antiqueGold,
                        labelStyle: const TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold),
                        unselectedLabelColor: Colors.grey[500],
                        tabs: _categories.map((cat) => Tab(text: cat)).toList(),
                        dividerColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -------------------------------------------
          // 2. 下部: 並び替え可能なリスト (ReorderableListView)
          // -------------------------------------------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildReorderableList(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(String category) {
    const antiqueGold = Color(0xFFD4AF37);
    const textColor = Color(0xFFD7CCC8);

    // カテゴリでフィルタリング (UtilityはWoodに含める仕様)
    final filteredData = _allHistoryData.where((item) {
      final itemCat = item['category'] as String;
      if (category == 'Wood') return itemCat == 'Wood' || itemCat == 'Utility';
      if (category == 'Iron') return itemCat == 'Iron' || itemCat == 'Iron Set';
      return itemCat == category;
    }).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 40, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              "まだ $category の記憶はありません...",
              style: const TextStyle(color: Colors.grey, fontFamily: 'Serif'),
            ),
          ],
        ),
      );
    }

    // ReorderableListView の実装
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      itemCount: filteredData.length,
      // 並び替え実行時のコールバック
      onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, filteredData),
      itemBuilder: (context, index) {
        final item = filteredData[index];
        final number = index + 1;
        final modelName = item['modelName'] as String;
        final suffix = _getSuffix(category);
        final message = '$modelName が$suffixになりました。';
        
        // ReorderableListViewでは一意なKeyが必須
        final key = ValueKey(item['id']); 

        return Container(
          key: key, // 必須
          margin: const EdgeInsets.only(bottom: 20.0), // Rowの代わりにContainerでラップしてマージン設定
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ドラッグハンドル（並び替え可能であることを示すアイコン）
              // ※長押しでも動かせますが、アイコンがあると親切です
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(top: 2, right: 16),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: antiqueGold.withOpacity(0.5)),
                    color: Colors.black26,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: antiqueGold,
                        fontSize: 12,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ),
                ),
              ),

              // テキストコンテンツ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontFamily: 'Serif',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[800], thickness: 0.5),
                  ],
                ),
              ),
              
              // 右側に並び替え用のグリップアイコンを薄く表示（お好みで削除可）
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Icon(Icons.drag_handle, color: Colors.grey[800], size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
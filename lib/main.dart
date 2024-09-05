import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");  // "assets/.env" ではなく ".env" を使用
  runApp(MaterialApp(home: ClaudePromptExample(),));
}

class ClaudePromptExample extends StatefulWidget {
  @override
  _ClaudePromptExampleState createState() => _ClaudePromptExampleState();
}

class _ClaudePromptExampleState extends State<ClaudePromptExample> {
  String _input = '';
  List<String> _questions = [];
  List<String> _worryElements = [];

  Future<void> callClaude() async {
    try {
    final apikey = dotenv.env['API_KEY'];
    if (apikey == null) {
      throw Exception('API_KEY not found in .env file');
    }
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final prompt = '''
#前提条件
タイトル: 悩みを聞いて核心に迫る質問を生成するプロンプト
依頼者条件: 質問力を向上させたい人、コミュニケーションスキルを磨きたい人
制作者条件: 質問の構造や深層心理に興味がある人、コーチングやカウンセリングの知識がある人

目的と目標: 依頼者が相手の本質や真意に迫る質問を作成できるよう支援するためのプロンプトを提供する。具体的な目標は、質問の明快さ、深さ、効果的なコミュニケーションへの貢献度を高めること。

リソース: コーチングやカウンセリングの手法、心理学の知識、コミュニケーションスキル向上の書籍やオンラインコース

評価基準: 生成された質問が相手の深層心理や本質に迫っているか、質問の構造が適切か、相手からの反応や回答が得られたかどうか、質問がコミュニケーションを深める効果があったかどうか

明確化の要件:
1. 質問は相手の感情や思考に寄り添ったものであること
2. 質問はオープンエンドであり、相手に考えさせる余地を残すこと
3. 質問は具体的であること、抽象的すぎないこと
4. 質問は相手に対する尊重と信頼を示すものであること
5. 質問は自己中心的ではなく、相手中心であること

#変数設定

悩みポスト="$_input"

#この内容を実行してください
step1:
{悩みポスト}の内容から
悩みの核心に迫る質問を{質問}に従いリスト変数に入れる形式で生成してください。
1つの質問ごとに,を入れてください。
不用意な番号や記号は書かないでください。

質問 = "質問={ , , , , , ,}"

step2:
悩みに対する要素を{悩み要素}に従いリスト変数に入れる形式で生成してください。1つの質問ごとに,を入れてください。不用意な番号や記号は書かないでください。

悩み要素="悩み={ , , , , , ,}"
''';

    final body = jsonEncode({
      "model": "claude-3-5-sonnet-20240620",
      "max_tokens": 1000,
      "messages": [
        {"role": "user", "content": prompt}
      ],
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apikey,
        'anthropic-version': '2023-06-01'
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _processResponse(data['content'][0]['text']);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}, ${response.body}');
    }
    }catch (e) {
    print('Error in callClaude: $e');
    setState(() {
      _questions = ['Error: $e'];
      _worryElements = ['Error occurred. Please try again.'];
    });
    }
  }

  void _processResponse(String responseText) {
    final questionsMatch = RegExp(r'質問=\{(.*?)\}').firstMatch(responseText);
    final worryElementsMatch = RegExp(r'悩み=\{(.*?)\}').firstMatch(responseText);

    if (questionsMatch != null) {
      _questions = questionsMatch.group(1)!.split(',').map((e) => e.trim()).toList();
    }

    if (worryElementsMatch != null) {
      _worryElements = worryElementsMatch.group(1)!.split(',').map((e) => e.trim()).toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claude Prompt Example')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => _input = value,
              decoration: InputDecoration(labelText: '悩みを入力してください'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: callClaude,
              child: Text('分析する'),
            ),
            SizedBox(height: 20),
            Text('質問:'),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_questions[index]));
                },
              ),
            ),
            Text('悩み要素:'),
            Expanded(
              child: ListView.builder(
                itemCount: _worryElements.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_worryElements[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
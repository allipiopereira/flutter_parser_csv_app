import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV Conciliator Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>>? csv1Data;
  List<List<dynamic>>? csv2Data;
  String resultMessage = "";

  Future<void> pickCSV(int fileNumber) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = result.files.single;
      final content = utf8.decode(file.bytes!);
      final fields = const CsvToListConverter().convert(content);

      setState(() {
        if (fileNumber == 1) {
          csv1Data = fields;
        } else {
          csv2Data = fields;
        }
      });
    }
  }

  void generateConciliatedCSV() {
    if (csv1Data == null || csv2Data == null) return;

    List<List<dynamic>> conciliatedData = [];
    List<dynamic> headers = ["Nome", "Idade", "Gênero/Endereço", "Conciliação"];
    conciliatedData.add(headers);

    for (var row1 in csv1Data!.skip(1)) {
      bool found = false;
      for (var row2 in csv2Data!.skip(1)) {
        if (row1[0] == row2[0] && row1[1] == row2[1]) {
          // Dados conciliados
          found = true;
          conciliatedData
              .add([row1[0], row1[1], row1[2] ?? row2[2], "Conciliado"]);
          break;
        }
      }
      if (!found) {
        // Não conciliados
        conciliatedData.add([row1[0], row1[1], row1[2], "Não conciliado"]);
      }
    }

    for (var row2 in csv2Data!.skip(1)) {
      bool found = false;
      for (var row1 in csv1Data!.skip(1)) {
        if (row2[0] == row1[0] && row2[1] == row1[1]) {
          found = true;
          break;
        }
      }
      if (!found) {
        // Não conciliados
        conciliatedData.add([row2[0], row2[1], row2[2], "Não conciliado"]);
      }
    }

    final csv = const ListToCsvConverter().convert(conciliatedData);

    // Criar um link para download
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "conciliated_data.csv")
      ..click();
    html.Url.revokeObjectUrl(url);

    setState(() {
      resultMessage = "CSV conciliado gerado e pronto para download.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CSV Conciliator Web"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () => pickCSV(1),
              child: Text("Selecionar CSV 1"),
            ),
            ElevatedButton(
              onPressed: () => pickCSV(2),
              child: Text("Selecionar CSV 2"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateConciliatedCSV,
              child: Text("Gerar CSV Conciliado"),
            ),
            SizedBox(height: 20),
            if (resultMessage.isNotEmpty) Text(resultMessage),
          ],
        ),
      ),
    );
  }
}
